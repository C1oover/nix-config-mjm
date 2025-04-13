{
  config,
  pkgs,
  lib,
  utils,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.prometheus;
in
{
  config = mkIf cfg.enable {
    systemd.services.prometheus-consul-exporter = {
      wantedBy = [ "multi-user.target" ];
      bindsTo = [ "netns-bridge@prometheus.service" ];
      after = [
        "network.target"
        "netns-bridge@prometheus.service"
      ];
      serviceConfig = {
        ExecStart = utils.escapeSystemdExecArgs [
          (lib.getExe pkgs.prometheus-consul-exporter)
          "--web.listen-address=127.0.0.1:9107"
          "--consul.server=consul.service.consul:8500"
        ];

        Restart = "always";
        PrivateTmp = true;
        WorkingDirectory = "/tmp";
        DynamicUser = true;
        User = "consul-exporter";
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NetworkNamespacePath = "/run/netns/prometheus";
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
