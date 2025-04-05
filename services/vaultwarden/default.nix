{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.vaultwarden;
  secrets = config.mjm.services.vaultwarden.vault.keys;
in
{
  options.mjm.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config = mkIf cfg.enable {
    mjm.services.vaultwarden = {
      vault = {
        enable = true;
        keys.backup_password = { };
      };
    };
    mjm.state.services = [ "vaultwarden" ];

    ingress.virtualHosts.pass = {
      upstream = {
        service.name = "vaultwarden";
        tls.enable = true;
      };

      enableAuthProxy = false;
    };

    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8221;
        DOMAIN = "https://pass.midna.dev";
      };
    };

    mjm.spire.tunnels.vaultwarden = {
      mode = "server";
      port = 8222;
      target = "localhost:8221";
    };

    services.consul.services.vaultwarden = {
      port = 8222;

      checks.up = {
        http.path = "/alive";
        http.tls = true;
      };
    };

    mjm.backups.vaultwarden = {
      passwordFile = secrets.backup_password.path;
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

    deployment.tests = {
      # these tests are unreliable for weird selenium reasons
      # vaultwarden = pkgs.nixosTests.vaultwarden.sqlite;
      # vaultwarden-backup = pkgs.nixosTests.vaultwarden.sqlite-backup;
    };
  };
}
