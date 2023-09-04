{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ingress;
  name = "ingress";
  # nginx 1.24.0
  image = "nginx@sha256:b1a2c7bcc61be621eae24851a976179bfbc72591e43c1fb340f7497ff72128ff";

  vhostType = with lib;
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        upstream = {
          name = mkOption {
            type = types.str;
            default = name;
          };
          addresses = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
          };
          path = mkOption {
            type = types.str;
            default = "";
          };
          ipHash = mkOption {
            type = types.bool;
            default = false;
          };
          useSSL = mkOption {
            type = types.bool;
            default = false;
          };
          service = {
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            port = mkOption {
              type = types.nullOr types.port;
              default = null;
            };
            connectPort = mkOption {
              type = types.nullOr types.port;
              default = null;
            };
          };
        };
        external = mkOption {
          type = types.bool;
          default = false;
        };
        enableAuthProxy = mkOption {
          type = types.bool;
          default = true;
        };
        recommendedProxySettings = mkOption {
          type = types.bool;
          default = true;
        };
        proxyWebsockets = mkOption {
          type = types.bool;
          default = true;
        };
        serverAliases = mkOption {
          type = types.listOf types.str;
          default = [];
        };
        extraServerConfig = mkOption {
          type = types.lines;
          default = "";
        };
        extraLocationConfig = mkOption {
          type = types.lines;
          default = "";
        };
      };
    };
in {
  options.ingress = {
    enable = mkEnableOption "Nomad ingress job";
    virtualHosts = mkOption {
      default = {};
      type = types.attrsOf (types.submodule vhostType);
    };
    extraTemplates = mkOption {
      default = {};
      type = types.attrs;
    };
  };

  config = mkIf cfg.enable (
    let
      vhosts = cfg.virtualHosts;
      upstreams = builtins.mapAttrs (_name: vhost: vhost.upstream) vhosts;

      nginxConfig = let
        upstreamBlocks =
          builtins.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList
            (name: u: ''
              upstream ${u.name} {
                ${lib.optionalString u.ipHash ''
                ip_hash;
              ''}
                ${
                if u.service.connectPort != null
                then "server 127.0.0.1:${toString u.service.connectPort};"
                else if u.addresses != null
                then lib.strings.concatMapStringsSep "\n" (a: "server ${a};") u.addresses
                else ''
                  {{ range service "${u.service.name}" }}
                  server {{ .Address }}:${
                    if u.service.port != null
                    then toString u.service.port
                    else "{{ .Port }}"
                  };
                  {{ else }}server 127.0.0.1:65535; # force a 502
                  {{ end }}
                ''
              }
              }
            '')
            upstreams);

        vhostServerBlocks =
          builtins.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList
            (name: vhost: let
              autheliaSuffix =
                if vhost.external
                then "-external"
                else "";
            in ''
              server {
                ${
                if vhost.external
                then ''
                  listen 80;
                  server_name ${name}.midna.dev ${builtins.concatStringsSep " " vhost.serverAliases};
                ''
                else ''
                  listen 443 ssl;
                  server_name ${name}.home.mattmoriarity.com ${builtins.concatStringsSep " " vhost.serverAliases};
                  ssl_certificate /etc/nginx/ssl/wildcard.pem;
                  ssl_certificate_key /etc/nginx/ssl/wildcard.pem;
                ''
              }

                ${lib.optionalString vhost.recommendedProxySettings ''
                proxy_buffering off;
                client_max_body_size 0;
              ''}
                ${vhost.extraServerConfig}
                ${lib.optionalString vhost.enableAuthProxy ''
                include /etc/nginx/include/authelia-location${autheliaSuffix}.conf;
              ''}
                location / {
                  ${lib.optionalString vhost.enableAuthProxy ''
                include /etc/nginx/include/authelia-request${autheliaSuffix}.conf;
              ''}

                  proxy_pass http${
                if vhost.upstream.useSSL
                then "s"
                else ""
              }://${vhost.upstream.name}${vhost.upstream.path};
                  ${lib.optionalString vhost.recommendedProxySettings ''
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Host $http_host;
                proxy_set_header X-Forwarded-Proto $scheme;
              ''}
                  ${lib.optionalString (vhost.recommendedProxySettings && (!vhost.external)) ''
                proxy_set_header X-Forwarded-Proto $scheme;
              ''}
                  ${lib.optionalString vhost.proxyWebsockets ''
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
              ''}
                  ${vhost.extraLocationConfig}
                }
              }
            '')
            vhosts);
      in
        builtins.readFile (pkgs.writers.writeNginxConfig "load-balancer.conf" ''
          # https://github.com/envoyproxy/envoy/issues/2506#issuecomment-362558239
          proxy_http_version 1.1;

          map $http_upgrade $connection_upgrade { # WebSocket support
            default upgrade;
            ''' ''';
          }

          ${upstreamBlocks}

          server {
            listen 80 default_server;
            server_name _;

            location /healthz {
              return 200 'nginx is listening';
            }

            location / {
              return 301 https://$host$request_uri;
            }
          }

          ${vhostServerBlocks}
        '');

      connectUpstreams =
        lib.attrsets.mapAttrs'
        (_name: u: {
          inherit (u.service) name;
          value = u.service.connectPort;
        })
        (lib.attrsets.filterAttrs (_name: u: u.service.connectPort != null) upstreams);
    in {
      nomad.jobs.ingress = {
        priority = 70;

        taskGroups.ingress = {
          count = 2;
          architecture = "arm64";

          ports.http.static = 80;
          ports.https.static = 443;

          services = [
            {
              name = "${name}-http";
              port = 80;
              connect = {
                enable = true;
                upstreams = connectUpstreams;
              };

              checks = [
                {
                  http.path = "/healthz";
                  # need to have some host header, value is arbitrary
                  http.headers.Host = ["ingress"];
                  interval = 15;
                  timeout = 3;
                }
              ];
            }
            {
              name = "${name}-https";
              port = 443;
            }
          ];

          tasks.nginx = {
            docker = {
              inherit image;
              volumes = [
                "local/include:/etc/nginx/include"
                "local/conf.d:/etc/nginx/conf.d"
                "secrets:/etc/nginx/ssl"
              ];
            };
            ports = ["http" "https"];
            cpu = 100;
            memory = 100;
            loggingTag = name;
            vault.policies = [name];
            vault.changeMode = "noop";

            templates =
              {
                "local/conf.d/load-balancer.conf" = {
                  text = nginxConfig;
                  changeMode = "signal";
                  changeSignal = "SIGHUP";
                };
                "local/include/authelia-request.conf".source = ./authelia-request.conf;
                "local/include/authelia-request-external.conf".source = ./authelia-request-external.conf;
                "local/include/authelia-location.conf".source = ./authelia-location.conf;
                "local/include/authelia-location-external.conf".source = ./authelia-location-external.conf;
                "secrets/wildcard.pem" = {
                  text = ''
                    {{ with secret "pki-homelab/issue/homelab" "common_name=*.home.mattmoriarity.com" -}}
                    {{ .Data.certificate }}
                    {{ .Data.private_key }}
                    {{ end }}
                  '';
                  changeMode = "signal";
                  changeSignal = "SIGHUP";
                };
              }
              // cfg.extraTemplates;
          };
        };
      };

      vault.policies.ingress.text = ''
        # Allow issuing *.homelab certificates for serving HTTPS pages
        path "pki-homelab/issue/homelab" {
          capabilities = ["update"]
        }
      '';

      resource.gitlab_repository_file.ingress_dns = {
        project = "30"; # mjm/nix-config
        file_path = "hosts/common/optional/dns-server/home.mattmoriarity.com.ingress.zone";
        branch = "main";
        commit_message = "dns-server: update ingress cnames";
        author_name = "Homelab Automation";
        author_email = "homelab@matt.mattmoriarity.com";

        content = let
          filteredVhosts = builtins.attrNames (lib.filterAttrs (_name: vhost: !vhost.external) vhosts);
          encodedContent = pkgs.runCommandLocal "encoded-zone" {} ''
            mkdir $out
            cat <<EOF | base64 -w0 > $out/zone
            ${builtins.concatStringsSep "\n" (map
              (name: "${name}  IN  CNAME ingress-http.service.consul.")
              filteredVhosts)}
            EOF
          '';
        in
          builtins.readFile "${encodedContent}/zone";
      };
    }
  );
}
