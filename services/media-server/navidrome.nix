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
    mjm.state.directories = [ "/var/lib/private/navidrome" ];

    services.navidrome = {
      enable = true;
      openFirewall = true;
      settings = {
        Address = "0.0.0.0";
        Port = 4533;
        BaseUrl = "https://music.midna.dev";
        MusicFolder = "/videos/music";
        "Prometheus.Enabled" = true;
        ReverseProxyWhitelist = "10.0.0.3/32,10.0.0.4/32,2601:282:167f:3eec:dea6:32ff:fed5:d840/64,2601:282:167f:3eec:dea6:32ff:fe96:bc05/64";
      };
    };

    systemd.services.navidrome = {
      # navidrome won't start without the music folder existing
      wants = [ "videos.mount" ];
      after = [ "videos.mount" ];
      serviceConfig.SupplementaryGroups = [ "media" ];
    };

    services.consul.services.navidrome = {
      port = config.services.navidrome.settings.Port;

      meta.metrics_path = "/metrics";

      checks = [
        {
          name = "navidrome is ready";
          http = "http://localhost:${toString config.services.navidrome.settings.Port}/ping";
          interval = "15s";
          timeout = "10s";
        }
      ];
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
