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
    mjm.services.vaultwarden = {
      vault.enable = true;
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/vaultwarden";
        user = "vaultwarden";
        group = "vaultwarden";
      }
    ];

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
        ROCKET_ADDRESS = "::1";
        ROCKET_PORT = 8221;
        DOMAIN = "https://pass.midna.dev";
      };
    };

    mjm.spire.tunnels = {
      vaultwarden = {
        mode = "server";
        listen.port = 8222;
        target.port = 8221;
        allowIngress = true;
      };
    };

    services.consul.services.vaultwarden = {
      port = 8222;

      checks.up = {
        http.path = "/alive";
        http.port = 8221;
      };
    };

    mjm.backups.vaultwarden = {
      paths = [
        "/var/lib/vaultwarden"
      ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 ".backup '/var/lib/vaultwarden/db-backup.sqlite3'"
      '';
      backupCleanupCommand = ''
        rm /var/lib/vaultwarden/db-backup.sqlite3
      '';
    };

    deployment.tests = {
      # these tests are unreliable for weird selenium reasons
      # vaultwarden = pkgs.nixosTests.vaultwarden.sqlite;
      # vaultwarden-backup = pkgs.nixosTests.vaultwarden.sqlite-backup;
    };
  };
}
