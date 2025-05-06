{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
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
        "10.0.150.3"
        "10.0.2.42"
        "10.0.150.9"
      ];
    };
  };

  imports = [
    ./unseal.nix
  ];

  config = mkIf cfg.enable {
    mjm.services.vault = {
      vault.enable = true;
    };

    ingress.virtualHosts.vault = {
      upstream = {
        service.name = "vault";
        tls.enable = true;
      };

      enableAuthProxy = false;
    };

    services.vault = {
      enable = true;
      package = pkgs.vault-bin;
      address = "0.0.0.0:8200";
      tlsCertFile = "/run/certs/vault/cert.pem";
      tlsKeyFile = "/run/certs/vault/key.pem";
      storageBackend = "raft";
      storageConfig = ''
        node_id = "${cfg.nodeId}"
      '';
      listenerExtraConfig = ''
        tls_min_version = "tls13"
        telemetry {
          unauthenticated_metrics_access = true
        }
      '';
      extraConfig = ''
        api_addr = "https://{{ GetPrivateIP }}:8200"
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

    mjm.spire.agent.enable = true;
    mjm.spire.certs.vault = {
      systemd.unit = "vault.service";
      systemd.action = "reload";
      user = "vault";
    };
    systemd.services.vault = {
      bindsTo = [ "spiffe-certs@vault.service" ];
      after = [ "spiffe-certs@vault.service" ];
      startLimitIntervalSec = lib.mkForce 0;
      serviceConfig.RestartSec = "5s";
    };

    mjm.backups.vault = {
      paths = [ "/tmp/vault.snap" ];
      backupPrepareCommand = ''
        export PATH=${
          lib.makeBinPath [
            config.services.vault.package
            pkgs.spire-agent
            pkgs.jq
          ]
        }:$PATH

        spire-agent api fetch -socketPath ${config.mjm.spire.agent.socketPath} -write /run/restic-backups-vault

        export VAULT_CACERT=/run/restic-backups-vault/bundle.0.pem
        export VAULT_ADDR=https://${config.networking.hostName}.node.consul:8200
        export VAULT_TLS_SERVER_NAME=vault.service.consul

        jwt="$(spire-agent api fetch jwt -audience https://vault.service.consul:8200 -output json -socketPath ${config.mjm.spire.agent.socketPath} | jq -r '.[0].svids[0].svid')"
        VAULT_TOKEN="$(vault write -field=token auth/spiffe/login role=spiffe jwt=$jwt)"
        export VAULT_TOKEN

        is_leader="$(vault read -field=is_self sys/leader)"
        if [ "$is_leader" = "true" ]; then
          vault operator raft snapshot save /tmp/vault.snap
        else
          echo "not the leader, skipping backup."
        fi
      '';
      backupCleanupCommand = ''
        rm -f /tmp/vault.snap
      '';
    };

    systemd.services.restic-backups-vault.serviceConfig = {
      # if not the leader, the backup command will fail, but we won't want to treat that as a failure.
      SuccessExitStatus = "1";
    };
  };
}
