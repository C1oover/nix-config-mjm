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

      checks.up = {
        http.path = "/alive";
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
  };
}
