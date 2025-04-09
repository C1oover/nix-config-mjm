{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.state.directories = [ "/var/lib/navidrome" ];

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
        MusicFolder = "/videos/music";
        "Prometheus.Enabled" = true;
        ReverseProxyWhitelist = "@";
      };
    };

    systemd.services.navidrome = {
      # navidrome won't start without the music folder existing
      wants = [ "videos.mount" ];
      after = [ "videos.mount" ];

      serviceConfig = {
        SupplementaryGroups = [ "media" ];
        # without this, navidrome can't read the dns config, which prevents reaching listenbrainz to scrobble
        BindReadOnlyPaths = [ "/run/systemd/resolve" ];
      };
    };

    mjm.spire.tunnels.navidrome = {
      mode = "server";
      port = 4533;
      target = "unix:/run/navidrome/server.sock";
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

    mjm.backups.mediaserver = {
      paths = [ "/var/lib/navidrome" ];
      exclude = [ "/var/lib/navidrome/cache" ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/navidrome/navidrome.db ".backup '/var/lib/navidrome/navidrome-backup.db'"
      '';
      backupCleanupCommand = ''
        rm /var/lib/navidrome/navidrome-backup.db
      '';
    };
  };
}
