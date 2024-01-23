{ pkgs, config, ... }:
{
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
    initialize = true;
    repository = "s3:http://garage.service.consul:3902/restic-backups/vaultwarden";
    passwordFile = config.age.secrets."vaultwarden-backup-password".path;
    environmentFile = config.age.secrets."backup.env".path;
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
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
  };

  age.secrets."backup.env".file = ../../../secrets/restic-backup-env.age;
  age.secrets."vaultwarden-backup-password".file = ../../../secrets/vaultwarden-backup-password.age;
}
