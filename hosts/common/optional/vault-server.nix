{
  pkgs,
  lib,
  utils,
  config,
  ...
}:
let
  inherit (lib)
    concatMapStrings
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.vault;

  pkg = pkgs.vault-unseal;
in
{
  options.mjm.vault = {
    enable = mkEnableOption "vault server";

    nodeId = mkOption {
      type = types.str;
      default = config.networking.hostName;
    };

    nodes = mkOption {
      type = types.listOf types.str;
      default = [
        "10.0.2.40"
        "10.0.2.42"
        "10.0.2.43"
      ];
    };
  };

  config = mkIf cfg.enable {
    services.vault = {
      enable = true;
      package = pkgs.vault-bin;
      address = "0.0.0.0:8200";
      storageBackend = "raft";
      storageConfig = ''
        node_id = "${cfg.nodeId}"
        ${concatMapStrings (n: ''
          retry_join {
            leader_api_addr = "http://${n}:8200"
          }
        '') cfg.nodes}
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

    mjm.state.directories = [
      {
        directory = config.services.vault.storagePath;
        user = "vault";
        group = "vault";
        mode = "0700";
      }
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
          ++ (map (n: "--nodes=http://${n}:8200") cfg.nodes)
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

    mjm.backups.vault =
      let
        vault = lib.getExe config.services.vault.package;
      in
      {
        passwordFile = config.age.secrets.vault-backup-password.path;
        useVaultSecrets = false;
        paths = [ "/tmp/vault.snap" ];
        backupPrepareCommand = ''
          role_id=05d0f7d5-f24c-5442-dbf1-46db0121fc14
          secret_id="$(cat ${config.age.secrets.vault-backup-secret-id.path})"

          export VAULT_ADDR=http://127.0.0.1:8200
          VAULT_TOKEN="$(${vault} write -field=token auth/approle/login role_id=$role_id secret_id=$secret_id)"
          export VAULT_TOKEN

          is_leader="$(${vault} read -field=is_self sys/leader)"
          if [ "$is_leader" = "true" ]; then
            ${vault} operator raft snapshot save /tmp/vault.snap
          else
            echo "not the leader, skipping backup."
          fi
        '';
        backupCleanupCommand = ''
          rm -f /tmp/vault.snap
        '';
      };

    # if not the leader, the backup command will fail, but we won't want to treat that as a failure.
    systemd.services.restic-backups-vault.serviceConfig.SuccessExitStatus = "1";

    age.secrets.vault-unseal-env.file = ../../../secrets/${config.networking.hostName}-vault-unseal-env.age;
    age.secrets.vault-backup-password.file = ../../../secrets/vault-backup-password.age;
    age.secrets.vault-backup-secret-id.file = ../../../secrets/vault-backup-secret-id.age;
  };
}
