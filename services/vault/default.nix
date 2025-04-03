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
        # extra test listener for TLS
        listener "tcp" {
          address = "0.0.0.0:8250"
          tls_cert_file = "/var/cache/vault/cert.pem"
          tls_key_file = "/var/cache/vault/key.pem"
          tls_min_version = "tls13"
        }

        api_addr = "http://{{ GetPrivateIP }}:8200"
        cluster_addr = "https://{{ GetPrivateIP }}:8201"
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
    deployment.tests = {
      # this triggers the unfree error for some reason, which is weird.
      # inherit (pkgs.nixosTests) vault;
    };

    networking.firewall.allowedTCPPorts = [
      8200
      8201
    ];

    mjm.authelia.oidcClients.vault = {
      name = "Hashicorp Vault";
      clientId = "3oGSHETQNzAa2Hd7CGaBAk08lskEJMKnR7YgMXMgWgqCsl9cWOuWzh2VT5LBu9fA";
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$QSmbERaC2fvE2IJnxScj2w$7TC9He52pllowLCVODoYOc8E1xS6cNrDSwyxvhqZdug";
      redirectUris = [
        "https://vault.midna.dev/oidc/callback"
        "https://vault.midna.dev/ui/vault/auth/oidc/oidc/callback"
        "http://localhost:8250/oidc/callback"
      ];
    };

    mjm.state.directories = [
      {
        directory = config.services.vault.storagePath;
        user = "vault";
        group = "vault";
        mode = "0700";
      }
    ];

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") === "vault.service" &&
            action.lookup("verb") === "reload" &&
            subject.user === "vault") {
          return polkit.Result.YES;
        }

        return polkit.Result.NOT_HANDLED;
      });
    '';

    mjm.spire.agent.enable = true;
    systemd.services.vault-certs =
      let
        configFile = pkgs.writeText "vault-spiffe-helper.hcl" ''
          agent_address = "/run/spire-agent/api.sock"
          cmd = "${pkgs.systemd}/bin/systemctl"
          cmd_args = "reload vault"
          cert_dir = "/var/cache/vault"
          daemon_mode = true
          svid_file_name = "cert.pem"
          svid_key_file_name = "key.pem"
          svid_bundle_file_name = "bundle.pem"
        '';
      in
      {
        wantedBy = [ "multi-user.target" ];
        before = [ "vault.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.spiffe-helper}/bin/spiffe-helper -config ${configFile}";
          CacheDirectory = "vault";
          User = "vault";
          Group = "vault";
        };
      };
    systemd.services.vault.serviceConfig.CacheDirectory = "vault";

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
  };
}
