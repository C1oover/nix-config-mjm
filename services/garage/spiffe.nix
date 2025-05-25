{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.garage;

  trustDomain = config.mjm.spire.agent.trustDomain;
in
{
  config = mkIf cfg.enable {
    mjm.services.spiffe-garage = { };

    systemd.sockets.spiffe-garage = {
      description = "SPIFFE Garage Credential Socket";
      wantedBy = [ "sockets.target" ];
      partOf = [ "spiffe-garage.service" ];
      socketConfig.ListenStream = "[::]:3899";
    };

    systemd.services.spiffe-garage = {
      description = "SPIFFE Garage Credential Service";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "spiffe-garage.socket"
        "spire-agent.service"
      ];
      requires = [ "spiffe-garage.socket" ];

      environment = {
        SPIFFE_ENDPOINT_SOCKET = "unix:${config.mjm.spire.agent.socketPath}";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318";
        OTEL_RESOURCE_ATTRIBUTES = "deployment.environment.name=prod";
      };
      credentials.garage.admin_token = { };

      serviceConfig = {
        Type = "notify-reload";
        ExecStart = "${pkgs.spiffe-tool}/bin/spiffe-garage";
        DynamicUser = true;
        Restart = "always";

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
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
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

    networking.firewall.allowedTCPPorts = [ 3899 ];

    services.consul.services.spiffe-garage = {
      port = 3899;

      # TODO health check
    };

    mjm.spire.entries.spiffe-garage = {
      spiffe_id = "spiffe://${trustDomain}/svc/spiffe-garage";
      selectors = [
        {
          type = "systemd";
          value = "id:spiffe-garage.service";
        }
      ];
      dns_names = [ "spiffe-garage.service.consul" ];
    };
  };
}
