{
  pkgs,
  lib,
  utils,
  config,
  outputs,
  ...
}:
let
  pkg = outputs.packages.${pkgs.system}.vault-unseal;
  nodes = [
    "10.0.2.40"
    "10.0.2.42"
    "10.0.2.43"
  ];
in
{
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "0.0.0.0:8200";
    storageBackend = "raft";
    storageConfig = ''
      node_id = "${config.networking.hostName}"
      ${lib.concatMapStrings
        (n: ''
          retry_join {
            leader_api_addr = "http://${n}:8200"
          }
        '')
        nodes}
    '';
    listenerExtraConfig = ''
      cluster_address = "0.0.0.0:8201"
      telemetry {
        unauthenticated_metrics_access = true
      }
    '';
    extraConfig = ''
      api_addr = "http://{{ GetInterfaceIP \"ens18\" }}:8200"
      cluster_addr = "https://{{ GetInterfaceIP \"ens18\" }}:8201"
      disable_mlock = true
      ui = true

      service_registration "consul" {
          address = "http://127.0.0.1:8500"
      }

      telemetry {
        disable_hostname = true
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    8200
    8201
  ];

  systemd.services.vault-unseal = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = utils.escapeSystemdExecArgs (
        [
          (lib.getExe pkg)
          "--environment=prod"
        ]
        ++ (map (n: "--nodes=http://${n}:8200") nodes)
      );
      EnvironmentFile = config.age.secrets.vault-unseal-env.path;
      Restart = "always";
      DynamicUser = true;
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      PrivateTmp = true;
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

  age.secrets.vault-unseal-env.file = ../../../secrets/${config.networking.hostName}-vault-unseal-env.age;
}
