{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.state.directories = [
      {
        directory = config.services.jellyfin.dataDir;
        inherit (config.services.jellyfin) user group;
      }
    ];

    ingress.virtualHosts.media = {
      upstream.service.name = "jellyfin";
      enableAuthProxy = false;
    };

    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    users.users.jellyfin.extraGroups = [ "media" ];

    services.consul.services.jellyfin = {
      port = 8096;

      checks.up = {
        http.path = "/health";
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    mjm.backups.mediaserver = {
      paths = [ "/var/lib/jellyfin" ];
      exclude = [
        "/var/lib/jellyfin/log"
        "/var/lib/jellyfin/transcodes"
      ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/jellyfin/data/jellyfin.db ".backup '/var/lib/jellyfin/data/jellyfin-backup.db'"
      '';
      backupCleanupCommand = ''
        rm /var/lib/jellyfin/data/jellyfin-backup.db
      '';
    };
  };
}
