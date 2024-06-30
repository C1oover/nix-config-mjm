{
  pkgs,
  config,
  lib,
  nodes,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMapStringsSep
    concatStrings
    filter
    filterAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mergeAttrsList
    mkEnableOption
    mkIf
    mkMerge
    optionalString
    ;
  cfg = config.ingress;

  vhosts = cfg.virtualHosts;
  upstreams = mapAttrs (_name: vhost: vhost.upstream) vhosts;
in
{
  imports = [ ./dns.nix ];

  options.mjm.ingress = {
    enable = mkEnableOption "ingress";
  };

  config = mkIf config.mjm.ingress.enable (mkMerge [
    {
      mjm.services.ingress = {
        vault = {
          enable = true;
          keys.cloudflare_api_token = { };
        };
      };
      vault-secrets.wantedBy = [ "acme-midna.dev.service" ];
      mjm.state.directories = [ "/var/lib/acme" ];

      security.acme = {
        acceptTerms = true;
        defaults = {
          # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
          email = "acme@matt.mattmoriarity.com";
          dnsResolver = "1.1.1.1:53";
          dnsProvider = "cloudflare";
          credentialFiles = {
            CF_DNS_API_TOKEN_FILE = config.mjm.services.ingress.vault.keys.cloudflare_api_token.path;
            CF_ZONE_API_TOKEN_FILE = config.mjm.services.ingress.vault.keys.cloudflare_api_token.path;
          };
        };
        certs = mapAttrs (name: _v: {
          dnsProvider = "cloudflare";
          webroot = null;
        }) (filterAttrs (_name: vhost: vhost.enableACME == true) config.services.nginx.virtualHosts);
      };

      services.nginx = {
        enable = true;

        logError = "syslog:server=unix:/dev/log";

        appendHttpConfig = ''
          access_log syslog:server=unix:/dev/log combined;
          include /run/nginx-include/upstreams.conf;
        '';

        virtualHosts =
          mapAttrs' (name: vhost: {
            name = "${name}.midna.dev";
            value = {
              serverAliases = vhost.serverAliases;
              forceSSL = true;
              useACMEHost = "midna.dev";
              extraConfig = ''
                ${optionalString vhost.recommendedProxySettings ''
                  proxy_buffering off;
                  client_max_body_size 0;
                ''}
                ${vhost.extraServerConfig}
                ${optionalString vhost.enableAuthProxy ''
                  include ${./authelia-location.conf};
                ''}
              '';

              locations."/" = {
                recommendedProxySettings = vhost.recommendedProxySettings;
                proxyWebsockets = vhost.proxyWebsockets;
                proxyPass = "http${
                  if vhost.upstream.useSSL then "s" else ""
                }://${vhost.upstream.name}${vhost.upstream.path}";
                extraConfig = ''
                  ${optionalString vhost.enableAuthProxy ''
                    include ${./authelia-request.conf};
                  ''}
                  ${vhost.extraLocationConfig}
                '';
              };
            };
          }) vhosts
          // {
            "midna.dev" = {
              default = true;
              serverAliases = [ "*.midna.dev" ];
              listen = [
                {
                  port = 80;
                  addr = "0.0.0.0";
                }
                {
                  port = 80;
                  addr = "[::]";
                }
              ];

              enableACME = true;

              locations."/healthz" = {
                return = "200 'nginx is listening'";
              };

              locations."/" = {
                return = "301 https://$host$request_uri";
              };
            };
          };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      systemd.tmpfiles.settings."10-nginx"."/run/nginx-include".d = {
        mode = "0755";
        user = "nginx";
        group = "nginx";
      };

      services.consul-template.instances.ingress = {
        enable = true;
        settings = {
          template = [
            {
              source = pkgs.writeText "upstreams.conf.tpl" (
                concatStrings (
                  mapAttrsToList (_name: u: ''
                    upstream ${u.name} {
                      ${optionalString u.ipHash ''
                        ip_hash;
                      ''}
                      ${
                        if u.addresses != null then
                          concatMapStringsSep "\n" (a: "server ${a};") u.addresses
                        else
                          ''
                            {{ range service "${u.service.name}" }}
                            server {{ if sprig_contains ":" .Address }}{{ .NodeTaggedAddresses.lan_ipv4 }}{{ else }}{{ .Address }}{{ end }}:${
                              if u.service.port != null then toString u.service.port else "{{ .Port }}"
                            };
                            {{ else }}server 127.0.0.1:65535; # force a 502
                            {{ end }}
                          ''
                      }
                    }
                  '') upstreams
                )
              );

              destination = "/run/nginx-include/upstreams.conf";
              user = "nginx";
              group = "nginx";
              exec.command = [
                "systemctl"
                "reload"
                "nginx.service"
              ];
            }
          ];
        };
      };

      systemd.services.nginx = {
        wants = [ "consul-template-ingress.service" ];
        after = [ "consul-template-ingress.service" ];
      };

      services.consul.services = {
        ingress-http = {
          port = 80;

          checks = [
            {
              http = "http://localhost/healthz";
              interval = "15s";
              timeout = "3s";
            }
          ];
        };
      };

      # vhosts for things that aren't running on NixOS machines
      ingress.virtualHosts = {
        proxmox = {
          upstream = {
            service.name = "proxmox";
            useSSL = true;
            ipHash = true;
          };

          enableAuthProxy = false;
        };

        containers = {
          upstream.addresses = [ "10.0.2.32:5050" ];

          enableAuthProxy = false;

          extraServerConfig = ''
            # To allow special characters in headers
            ignore_invalid_headers off;
            # Allow any size file to be uploaded.
            proxy_request_buffering off;
            proxy_connect_timeout       300;
            proxy_send_timeout          300;
            proxy_read_timeout          300;
            send_timeout                300;
          '';

          extraLocationConfig = ''
            proxy_redirect off;
          '';
        };

        git = {
          upstream.addresses = [ "10.0.2.32" ];

          enableAuthProxy = false;
          useIPv4Proxy = true;

          extraServerConfig = ''
            # To allow special characters in headers
            ignore_invalid_headers off;
            # Allow any size file to be uploaded.
            proxy_request_buffering off;
            proxy_connect_timeout       300;
            proxy_send_timeout          300;
            proxy_read_timeout          300;
            send_timeout                300;
          '';

          extraLocationConfig = ''
            proxy_redirect off;
          '';
        };

        pages = {
          upstream.addresses = [ "10.0.2.33" ];
          serverAliases = [
            "*.pages.midna.dev"
            "www.midna.dev"
            "midna.dev"
          ];
          enableAuthProxy = false;

          extraServerConfig = ''
            location =/.well-known/matrix/server {
              default_type application/json;
              return 200 '{"m.server": "chat.midna.dev:443"}';
            }

            location =/.well-known/matrix/client {
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '{"m.homeserver": {"base_url": "https://chat.midna.dev/"}, "org.matrix.msc3575.proxy": {"url": "https://chat.midna.dev"}}';
            }
          '';
        };
      };
    }
    {
      ingress.virtualHosts =
        let
          allNodes = attrValues nodes;
          nonIngressNodes = filter (node: !node.config.mjm.ingress.enable) allNodes;
        in
        mergeAttrsList (map (node: node.config.ingress.virtualHosts) nonIngressNodes);
    }
  ]);
}
