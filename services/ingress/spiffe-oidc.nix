{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.ingress;

  pkg = pkgs.spire.overrideAttrs (old: {
    subPackages = old.subPackages ++ [ "support/oidc-discovery-provider" ];
  });

  configFile = pkgs.writeText "oidc-discovery-provider.hcl" ''
    domains = ["spiffe.midna.dev"]
    listen_socket_path = "/run/oidc-discovery-provider/server.sock"

    workload_api {
      socket_path = "/run/spire-agent/api.sock"
      trust_domain = "home.mattmoriarity.com"
    }
  '';
in
{
  config = mkIf cfg.enable {
    services.caddy.settings.apps.http.servers.default.routes = [
      {
        match = [ { host = [ "spiffe.midna.dev" ]; } ];
        handle = [
          {
            handler = "reverse_proxy";
            upstreams = [
              { dial = "unix//run/oidc-discovery-provider/server.sock"; }
            ];
          }
        ];
      }
    ];

    systemd.services.oidc-discovery-provider = {
      wantedBy = [ "multi-user.target" ];
      after = [ "spire-agent.service" ];
      serviceConfig = {
        ExecStart = "${pkg}/bin/oidc-discovery-provider -config ${configFile}";
        DynamicUser = true;
        Restart = "on-failure";
        RuntimeDirectory = "oidc-discovery-provider";
      };
    };
  };
}
