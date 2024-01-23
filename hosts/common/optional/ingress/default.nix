{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.ingress;
  vhosts = cfg.virtualHosts;
  upstreams = builtins.mapAttrs (_name: vhost: vhost.upstream) vhosts;
  connectUpstreams = lib.filterAttrs (_name: u: u.service.connectPort != null) upstreams;
in
{
  imports = [ ../../../../apps ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      email = "acme@matt.mattmoriarity.com";
      dnsResolver = "1.1.1.1:53";
      dnsProvider = "cloudflare";
      credentialFiles = {
        CF_DNS_API_TOKEN_FILE = config.age.secrets."cloudflare-api-token".path;
        CF_ZONE_API_TOKEN_FILE = config.age.secrets."cloudflare-api-token".path;
      };
    };
    certs =
      builtins.mapAttrs
        (name: _v: {
          dnsProvider = "cloudflare";
          webroot = null;
        })
        (lib.filterAttrs (_name: vhost: vhost.enableACME == true) config.services.nginx.virtualHosts);
  };

  services.nginx = {
    enable = true;

    appendHttpConfig = ''
      include /run/nginx-include/upstreams.conf;
    '';

    upstreams =
      lib.mapAttrs'
        (_name: u: {
          inherit (u) name;

          value = {
            servers = {
              "127.0.0.1:${toString u.service.connectPort}" = { };
            };
            extraConfig = lib.mkIf u.ipHash ''
              ip_hash;
            '';
          };
        })
        connectUpstreams;

    virtualHosts =
      lib.mapAttrs'
        (name: vhost: {
          name = "${name}.midna.dev";
          value = {
            serverAliases = vhost.serverAliases;
            forceSSL = true;
            enableACME = true;
            extraConfig = ''
              ${lib.optionalString vhost.recommendedProxySettings ''
                proxy_buffering off;
                client_max_body_size 0;
              ''}
              ${vhost.extraServerConfig}
              ${lib.optionalString vhost.enableAuthProxy ''
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
                ${lib.optionalString vhost.enableAuthProxy ''
                  include ${./authelia-request.conf};
                ''}
                ${vhost.extraLocationConfig}
              '';
            };
          };
        })
        vhosts
      // {
        "_" = {
          default = true;
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
          source =
            let
              nonConnectUpstreams = builtins.filter (u: u.service.connectPort == null) (
                lib.mapAttrsToList (_name: u: u) upstreams
              );
            in
            pkgs.writeText "upstreams.conf.tpl" (
              lib.concatStrings (
                map
                  (u: ''
                    upstream ${u.name} {
                      ${lib.optionalString u.ipHash ''
                      ip_hash;
                    ''}
                      ${
                        if u.addresses != null then
                          lib.concatMapStringsSep "\n" (a: "server ${a};") u.addresses
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
                  '')
                  nonConnectUpstreams
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

  systemd.services.nginx.wants = [ "consul-template-ingress.service" ];

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
    ingress-http-proxy = {
      port = 10080;
      kind = "connect-proxy";
      proxy = {
        destination_service_id = config.services.consul.services.ingress-http.id;
        destination_service_name = "ingress-http";
        local_service_address = "127.0.0.1";
        local_service_port = 80;
        config = {
          bind_address = "[::]";
        };
        upstreams =
          lib.mapAttrsToList
            (_name: u: {
              destination_name = u.service.name;
              local_bind_port = u.service.connectPort;
            })
            connectUpstreams;
      };
    };
  };

  systemd.services.consul-connect = {
    path = with pkgs; [
      consul
      envoy
    ];
    script = ''
      consul connect envoy -proxy-id ${config.services.consul.services.ingress-http-proxy.id} -envoy-version ${pkgs.envoy.version}
    '';
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "consul.service"
    ];
    serviceConfig = {
      DynamicUser = true;
      Restart = "always";
      RestartSec = "10s";
    };
  };

  age.secrets."cloudflare-api-token".file = ../../../../secrets/cloudflare-api-token.age;
}
