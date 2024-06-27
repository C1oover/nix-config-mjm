{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.vaultwarden;
in
{
  options.mjm.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config = mkIf cfg.enable {
    mjm.state.directories = [
      {
        directory = "/var/lib/bitwarden_rs";
        user = "vaultwarden";
        group = "vaultwarden";
      }
    ];
    deployment.tags = [ "svc-vaultwarden" ];

    ingress.virtualHosts.pass = {
      upstream.service.name = "vaultwarden";

      enableAuthProxy = false;
    };

    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "::";
        ROCKET_PORT = 8222;
        DOMAIN = "https://pass.midna.dev";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8222 ];

    services.consul.services.vaultwarden = {
      port = 8222;

      checks = [
        {
          name = "vaultwarden is alive";
          http = "http://localhost:8222/alive";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };

    mjm.backups.vaultwarden = {
      passwordFile = config.vault-secrets.services.vaultwarden.keys.backup_password.path;
      paths = [
        "/var/lib/bitwarden_rs/attachments"
        "/var/lib/bitwarden_rs/db-backup.sqlite3"
      ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/bitwarden_rs/db.sqlite3 ".backup '/var/lib/bitwarden_rs/db-backup.sqlite3'"
      '';
      backupCleanupCommand = ''
        rm /var/lib/bitwarden_rs/db-backup.sqlite3
      '';
    };

    vault.services.vaultwarden = { };
    vault-secrets.services.vaultwarden = {
      keys.backup_password = { };
    };
  };
}
