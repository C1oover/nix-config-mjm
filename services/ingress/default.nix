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
    optional
    pipe
    ;

  cfg = config.mjm.ingress;

  vhosts = pipe nodes [
    attrValues
    (filter (node: !node.config.mjm.ingress.enable))
    (map (node: node.config.ingress.virtualHosts))
    mergeAttrsList
  ];
in
{
  imports = [
    ./mta-sts.nix
    ./spiffe-oidc.nix
  ];

  options.mjm.ingress = {
    enable = mkEnableOption "ingress";
  };

  config = mkIf cfg.enable {
    mjm.services.caddy = {
      vault.enable = true;
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/caddy";
        inherit (config.services.caddy) user group;
      }
    ];

    services.caddy = {
      enable = true;
      package = pkgs.caddy-desec;
      settings = {
        apps.tls = {
          certificates.automate = [
            "midna.dev"
            "*.midna.dev"
            "*.mattmoriarity.com"
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
                      token = "{file./run/credentials/caddy.service/caddy_desec_api_token}";
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
                      routes =
                        let
                          setHeader = name: {
                            handle = [
                              {
                                handler = "headers";
                                request.set.${name} = [ "{http.reverse_proxy.header.${name}}" ];
                              }
                            ];
                            match = [
                              {
                                not = [
                                  { vars."{http.reverse_proxy.header.${name}}" = [ "" ]; }
                                ];
                              }
                            ];
                          };
                        in
                        [
                          {
                            handle = [ { handler = "vars"; } ];
                          }
                        ]
                        ++ map setHeader [
                          "Remote-User"
                          "Remote-Groups"
                          "Remote-Name"
                          "Remote-Email"
                        ];
                    }
                  ];
                  handler = "reverse_proxy";
                  transport = {
                    protocol = "http";
                    tls = {
                      ca = {
                        provider = "file";
                        pem_files = [ "/run/certs/caddy/bundle.pem" ];
                      };
                      server_name = "authelia.service.consul";
                      client_certificate_file = "/run/certs/caddy/cert.pem";
                      client_certificate_key_file = "/run/certs/caddy/key.pem";
                    };
                  };
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
                  transport = mkIf upstream.tls.enable {
                    protocol = "http";
                    tls = {
                      ca = {
                        provider = "file";
                        pem_files = [ "/run/certs/caddy/bundle.pem" ];
                      };
                      server_name = "${upstream.service.name}.service.consul";
                      client_certificate_file = "/run/certs/caddy/cert.pem";
                      client_certificate_key_file = "/run/certs/caddy/key.pem";
                    };
                  };
                  dynamic_upstreams =
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
                    );
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
              errors.routes = [
                {
                  match = [
                    {
                      vars."{http.error.status_code}" = [ "503" ];
                      vars."{http.error.message}" = [ "no upstreams available" ];
                    }
                  ];
                  handle = [
                    {
                      handler = "static_response";
                      body = "Sorry, no proxy upstreams are available. This means either the service you're accessing or Authelia have no healthy backends right now.";
                    }
                  ];
                }
                {
                  handle = [
                    {
                      handler = "static_response";
                      body = "Sorry, something went wrong: {http.error.message}\n\nThe error came from {http.error.trace}";
                    }
                  ];
                }
              ];
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

      metrics.enable = true;
      metrics.port = 2020;

      checks.up = {
        http.url = "http://localhost:2019/reverse_proxy/upstreams";
      };
    };

    mjm.spire.agent.enable = true;
    mjm.spire.certs.caddy = {
      systemd.unit = "caddy.service";
      systemd.action = "reload-or-restart";
      user = "caddy";
    };

    systemd.services.caddy = {
      bindsTo = [ "spiffe-certs@caddy.service" ];
      after = [ "spiffe-certs@caddy.service" ];
      credentials.caddy.desec_api_token = { };
    };
  };
}
