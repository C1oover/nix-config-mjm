{ config, pkgs, ... }:
{
  imports = [ ../../common/optional/backup.nix ];

  mjm.backups.mediaserver = {
    repositoryName = "mediaserver";
    passwordFile = config.vault-secrets.templates.mediaserver-backup-password.path;
    paths = [
      "/var/lib/jellyfin"
      "/var/lib/sabnzbd/admin"
      "/var/lib/sabnzbd/sabnzbd.ini"
      "/var/lib/sonarr/.config/NzbDrone"
      "/var/lib/radarr/.config/Radarr"
      "/var/lib/readarr"
    ];
    exclude = [
      "/var/lib/jellyfin/log"
      "/var/lib/jellyfin/transcodes"
      "/var/lib/sonarr/.config/NzbDrone/logs"
      "/var/lib/radarr/.config/Radarr/logs"
      "/var/lib/readarr/logs"
    ];
    backupPrepareCommand = ''
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/jellyfin/data/jellyfin.db ".backup '/var/lib/jellyfin/data/jellyfin-backup.db'"
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/sonarr/.config/NzbDrone/sonarr.db ".backup '/var/lib/sonarr/.config/NzbDrone/sonarr-backup.db'"
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/radarr/.config/Radarr/radarr.db ".backup '/var/lib/radarr/.config/Radarr/radarr-backup.db'"
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/readarr/readarr.db ".backup '/var/lib/readarr/readarr-backup.db'"
    '';
    backupCleanupCommand = ''
      rm /var/lib/jellyfin/data/jellyfin-backup.db
      rm /var/lib/sonarr/.config/NzbDrone/sonarr-backup.db
      rm /var/lib/radarr/.config/Radarr/radarr-backup.db
      rm /var/lib/readarr/readarr-backup.db
    '';
  };

  vault-secrets.templates.mediaserver-backup-password.kvPath = "kv/mediaserver/backup_password";
}
