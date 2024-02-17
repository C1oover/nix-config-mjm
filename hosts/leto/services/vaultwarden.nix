{ pkgs, config, ... }:
{
  imports = [ ../../common/optional/backup.nix ];

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

  services.restic.backups.vaultwarden = {
    repositoryName = "vaultwarden";
    passwordFile = config.vault-secrets.templates.vaultwarden-backup-password.path;
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

  vault-secrets.templates.vaultwarden-backup-password.text = ''{{ with secret "kv/vaultwarden" }}{{ .Data.data.backup_password }}{{ end }}'';
}
