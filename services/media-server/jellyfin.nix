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

    mjm.authelia.oidcClients.jellyfin = {
      name = "Jellyfin";
      clientId = "3n3vR0P8cJuVbgXK3TVYWSG7joDrITANJ2YzjU3wdg8PMeSPd6U7ZBOuQp4X9cf8";
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$lBl0VCuHURqxh1quwbEoWQ$4g4sGOcrvljimFwENZiOwinCcRZDgVl+bh1nE3T93Tg";
      requirePkce = true;
      redirectUris = [ "https://media.midna.dev/sso/OID/redirect/authelia" ];
      scopes = [
        "openid"
        "profile"
        "groups"
      ];
      tokenEndpointAuthMethod = "client_secret_post";
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

    mjm.backups.media-server = {
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
