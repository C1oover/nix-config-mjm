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
      socket_path = "${config.mjm.spire.agent.socketPath}"
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

        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateIPC = true;
        PrivateUsers = "identity";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [ "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "~@resources @privileged"
        ];
        UMask = "0077";
      };
    };
  };
}
