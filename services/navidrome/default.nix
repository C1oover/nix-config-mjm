{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.navidrome;
in
{
  options.mjm.navidrome = {
    enable = mkEnableOption "Navidrome";
  };

  config = mkIf cfg.enable {
    mjm.state.directories = [ "/var/lib/navidrome" ];
    microvm.shares = [
      {
        proto = "virtiofs";
        tag = "music";
        source = "/mnt/slow/media/music";
        mountPoint = "/mnt/music";
      }
    ];

    ingress.virtualHosts.music = {
      upstream = {
        service.name = "navidrome";
        tls.enable = true;
      };
    };

    services.navidrome = {
      enable = true;
      settings = {
        # /run/navidrome is / inside the service
        Address = "unix:/server.sock";
        UnixSocketPerm = "0666";
        BaseUrl = "https://music.midna.dev";
        MusicFolder = "/mnt/music";
        "Prometheus.Enabled" = true;
        ReverseProxyWhitelist = "@";
      };
    };

    systemd.services.navidrome = {
      # navidrome won't start without the music folder existing
      unitConfig.RequiresMountsFor = [ "/mnt/music" ];
    };

    mjm.spire.tunnels.navidrome = {
      mode = "server";
      listen.port = 4533;
      target.socket = "/run/navidrome/server.sock";
      allowIngress = true;
      allowMetrics = true;
    };

    services.consul.services.navidrome = {
      port = 4533;
      metrics.enable = true;
      metrics.tls = true;

      checks.up = {
        http.path = "/ping";
        http.socket = "/run/navidrome/server.sock";
      };
    };

    # TODO navidrome will need vault set up for the password
    # mjm.backups.navidrome = {
    #   paths = [ "/var/lib/navidrome" ];
    #   exclude = [ "/var/lib/navidrome/cache" ];
    #   backupPrepareCommand = ''
    #     ${pkgs.sqlite}/bin/sqlite3 /var/lib/navidrome/navidrome.db ".backup '/var/lib/navidrome/navidrome-backup.db'"
    #   '';
    #   backupCleanupCommand = ''
    #     rm /var/lib/navidrome/navidrome-backup.db
    #   '';
    # };
  };
}
