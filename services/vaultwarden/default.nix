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

    mjm.spire.agent.enable = true;
    systemd.sockets.vaultwarden-tunnel = {
      wantedBy = [ "sockets.target" ];
      partOf = [ "vaultwarden-tunnel.service" ];
      socketConfig = {
        FileDescriptorName = "ghostunnel";
        ListenStream = "[::]:8222";
      };
    };

    systemd.services.vaultwarden-tunnel = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "vaultwarden-tunnel.socket"
      ];
      requires = [ "vaultwarden-tunnel.socket" ];

      environment.SPIFFE_ENDPOINT_SOCKET = "unix:/run/spire-agent/api.sock";

      serviceConfig = {
        Type = "notify-reload";
        ExecStart = "${pkgs.ghostunnel}/bin/ghostunnel server --listen=systemd:ghostunnel --target=localhost:8221 --use-workload-api --disable-authentication";
        DynamicUser = true;
        Restart = "always";
        WatchdogSec = 1;
      };
    };

    networking.firewall.allowedTCPPorts = [ 8222 ];

    services.consul.services.vaultwarden = {
      port = 8222;

      checks.up = {
        # TODO hit the TLS one
        http.url = "http://localhost:8221/alive";
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
