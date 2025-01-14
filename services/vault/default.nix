{
  pkgs,
  lib,
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

  imports = [
    ./admin.nix
    ./auth.nix
    ./mounts.nix
    ./unseal.nix
  ];

  config = mkIf cfg.enable {
    mjm.services.vault = { };

    ingress.virtualHosts.vault = {
      upstream.service.name = "vault";

      enableAuthProxy = false;
    };

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

    deployment.consulChecks = [ "vault" ];

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

    mjm.backups.vault =
      let
        vault = lib.getExe config.services.vault.package;
      in
      {
        passwordFile = config.vault-secrets.services.vault.keys.backup_password.path;
        paths = [ "/tmp/vault.snap" ];
        backupPrepareCommand = ''
          role_id=${config.vault-secrets.roleId}
          secret_id_file="$CREDENTIALS_DIRECTORY/secret-id"

          export VAULT_ADDR=http://127.0.0.1:8200
          VAULT_TOKEN="$(${vault} write -field=token auth/approle/login role_id=$role_id secret_id=@$secret_id_file)"
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

    vault.services.vault.paths = {
      "sys/leader".capabilities = [ "read" ];
      "sys/storage/raft/snapshot".capabilities = [ "read" ];
    };
    vault-secrets.services.vault = {
      keys.backup_password = { };
    };

    systemd.services.restic-backups-vault.serviceConfig = {
      # if not the leader, the backup command will fail, but we won't want to treat that as a failure.
      SuccessExitStatus = "1";

      inherit (config.systemd.services.render-vault-secrets.serviceConfig) LoadCredentialEncrypted;
    };

    terraform.terraform.required_providers.vault = {
      source = "registry.opentofu.org/hashicorp/vault";
      version = ">= 3.0.0";
    };

    terraform.provider.vault = { };
  };
}
