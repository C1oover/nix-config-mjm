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
    };

    services.consul.services.navidrome = {
      port = 4533;
      metrics.enable = true;

      checks.up = {
        # consul can't do normal http checks to unix sockets, and the
        # tunnel only allows requests from the ingress, so here we are.
        script.args = [
          (lib.getExe pkgs.curl)
          "--no-progress-meter"
          "--fail-with-body"
          "--unix-socket"
          "/run/navidrome/server.sock"
          "http://localhost/ping"
        ];
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
