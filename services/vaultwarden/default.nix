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
      vault = {
        enable = true;
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
        ROCKET_ADDRESS = "::1";
        ROCKET_PORT = 8221;
        DOMAIN = "https://pass.midna.dev";
      };
    };

    systemd.services.vaultwarden = {
      bindsTo = [ "netns-bridge@vaultwarden.service" ];
      serviceConfig.NetworkNamespacePath = "/run/netns/vaultwarden";
    };

    mjm.spire.tunnels = {
      vaultwarden = {
        mode = "server";
        listen.port = 8222;
        target.port = 8221;
        target.namespace = "vaultwarden";
        allowIngress = true;
        allowConsul = true;
      };
      consul-vaultwarden = {
        mode = "client";
        listen.socket = "/run/consul-checks/vaultwarden.sock";
        target.port = 8222;
        service = "vaultwarden";
      };
    };

    services.consul.services.vaultwarden = {
      port = 8222;

      checks.up = {
        http.path = "/alive";
        http.socket = "/run/consul-checks/vaultwarden.sock";
      };
    };

    mjm.backups.vaultwarden = {
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
