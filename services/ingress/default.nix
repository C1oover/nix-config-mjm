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
    filter
    mergeAttrsList
    mkEnableOption
    mkIf
    mkMerge
    optional
    ;
  cfg = config.ingress;

  vhosts = cfg.virtualHosts;

  caddy = (import ../../packages { inherit pkgs; }).caddy-desec;
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
          keys.desec_api_token = {
            owner = "caddy";
          };
        };
      };
      vault-secrets.wantedBy = [ "caddy.service" ];
      mjm.state.directories = [ "/var/lib/caddy" ];

      services.caddy = {
        enable = true;
        package = caddy;
        settings = {
          apps.tls = {
            certificates.automate = [
              "midna.dev"
              "*.midna.dev"
            ];
            automation.policies = [
              {
                issuers = [
                  {
                    module = "acme";
                    email = "acme@matt.mattmoriarity.com";
                    challenges.dns = {
                      propagation_delay = "30s";
                      propagation_timeout = "30m";
                      provider = {
                        name = "desec";
                        token = "{file.${config.mjm.services.ingress.vault.keys.desec_api_token.path}}";
                      };
                      resolvers = [
                        "1.1.1.1"
                        "1.0.0.1"
                      ];
                    };
                  }
                ];
              }
            ];
          };
          apps.http =
            let
              authProxyRoute = {
                handle = [
                  {
                    handle_response = [
                      {
                        match.status_code = [ 2 ];
                        routes = [
                          {
                            handle = [
                              {
                                handler = "headers";
                                request.set = {
                                  Remote-Email = [ "{http.reverse_proxy.header.Remote-Email}" ];
                                  Remote-Groups = [ "{http.reverse_proxy.header.Remote-Groups}" ];
                                  Remote-Name = [ "{http.reverse_proxy.header.Remote-Name}" ];
                                  Remote-User = [ "{http.reverse_proxy.header.Remote-User}" ];
                                };
                              }
                            ];
                          }
                        ];
                      }
                    ];
                    handler = "reverse_proxy";
                    dynamic_upstreams = {
                      source = "srv";
                      service = "authelia";
                      proto = "tcp";
                      name = "service.consul";
                      refresh = "15s";
                      # TODO probably add resolver addresses to directly connect to consul
                    };
                    rewrite = {
                      method = "GET";
                      uri = "/api/authz/forward-auth";
                    };
                    headers.request.set = {
                      X-Forwarded-Method = [ "{http.request.method}" ];
                      X-Forwarded-Uri = [ "{http.request.uri}" ];
                    };
                  }
                ];
              };
              mkUpstreamRoute = upstream: {
                handle = [
                  {
                    handler = "reverse_proxy";
                    load_balancing = mkIf upstream.ipHash { selection_policy.policy = "ip_hash"; };
                    transport = mkIf upstream.useSSL {
                      protocol = "http";
                      tls = {
                        insecure_skip_verify = true;
                      };
                    };
                    dynamic_upstreams = mkIf (upstream.service.name != null) (
                      {
                        refresh = "15s";
                        # TODO probably add resolver addresses to directly connect to consul
                      }
                      // (
                        if upstream.service.port == null then
                          {
                            source = "srv";
                            service = upstream.service.name;
                            proto = if upstream.service.tag != null then upstream.service.tag else "tcp";
                            name = "service.consul";
                          }
                        else
                          {
                            source = "a";
                            name = "${upstream.service.name}.service.consul";
                            port = toString upstream.service.port;
                          }
                      )
                    );
                    upstreams = mkIf (upstream.addresses != null) (map (addr: { dial = addr; }) upstream.addresses);
                  }
                ];
              };
              mkVhostRoute = vhost: {
                match = [ { host = [ "${vhost.name}.midna.dev" ] ++ vhost.serverAliases; } ];
                handle = [
                  {
                    handler = "subroute";
                    routes =
                      (optional vhost.enableAuthProxy authProxyRoute)
                      ++ vhost.extraRoutes
                      ++ [ (mkUpstreamRoute vhost.upstream) ];
                  }
                ];
              };
            in
            {
              servers.default = {
                listen = [ ":443" ];
                logs = { };
                metrics = { };
                automatic_https.disable_certificates = true;
                routes = map mkVhostRoute (attrValues vhosts);
              };
              servers.metrics = {
                listen = [ ":2020" ];
                automatic_https.disable = true;
                routes = [ { handle = [ { handler = "metrics"; } ]; } ];
              };
            };
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
        2020
      ];

      services.consul.services.caddy = {
        port = 443;

        meta.metrics_path = "/metrics";
        meta.metrics_port = "2020";

        checks = [
          {
            name = "caddy is healthy";
            http = "http://localhost:2019/reverse_proxy/upstreams";
            interval = "15s";
            timeout = "3s";
          }
        ];
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
        };

        git = {
          upstream.addresses = [ "10.0.2.32:80" ];

          enableAuthProxy = false;
          useIPv4Proxy = true;
        };

        pages = {
          upstream.addresses = [ "10.0.2.33:80" ];
          serverAliases = [
            "*.pages.midna.dev"
            "www.midna.dev"
            "midna.dev"
          ];
          enableAuthProxy = false;

          extraRoutes = [
            {
              match = [ { path = [ "/.well-known/matrix/server" ]; } ];
              handle = [
                {
                  handler = "static_response";
                  body = builtins.toJSON { "m.server" = "chat.midna.dev:443"; };
                }
              ];
            }
            {
              match = [ { path = [ "/.well-known/matrix/client" ]; } ];
              handle = [
                {
                  handler = "headers";
                  response.set.Access-Control-Allow-Origin = [ "*" ];
                }
                {
                  handler = "static_response";
                  body = builtins.toJSON {
                    "m.homeserver".base_url = "https://chat.midna.dev/";
                    "org.matrix.msc3575.proxy".url = "https://chat.midna.dev";
                  };
                }
              ];
            }
          ];
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
