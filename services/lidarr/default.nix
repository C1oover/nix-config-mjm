{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cloover.lidarr;

  inherit (config.services.lidarr) dataDir;
in
{
  options.cloover.lidarr = {
    enable = mkEnableOption "Lidarr";
  };

  config = mkIf cfg.enable {
    cloover.services.lidarr = {
      vault.enable = true;
    };
    cloover.state.directories = [
      {
        directory = dataDir;
        inherit (config.services.lidarr) user group;
      }
    ];
    microvm.shares = [
      {
        proto = "virtiofs";
        tag = "media";
        source = "/mnt/slow/media";
        mountPoint = "/videos";
      }
    ];

    services.lidarr = {
      enable = true;
      settings.server.bindaddress = "localhost";
    };

    users.groups.media.gid = 997;
    users.users.lidarr.extraGroups = [ "media" ];

    systemd.tmpfiles.settings."10-lidarr" = {
      "/videos/music" = {
        d = {
          user = "lidarr";
          group = "media";
        };
        Z = {
          user = "lidarr";
          group = "media";
          mode = "~0775";
        };
      };
    };

    services.prometheus.exporters.exportarr-lidarr = {
      enable = true;
      listenAddress = "::1";
      apiKeyFile = "/run/lidarr-creds.sock";
      url = "http://127.0.0.1:8686";
    };

    cloover.spire.creds = {
      lidarr.aliases = {
        "prometheus-exportarr-lidarr-exporter.service/api-key" = "lidarr/api_key";
      };
    };

    cloover.spire.tunnels = {
      lidarr = {
        id = "lidarr";
        mode = "server";
        listen.port = 18686;
        target.port = 8686;
        allowIngress = true;
      };
      lidarr-sabnzbd = {
        id = "lidarr";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        target.service = "sabnzbd";
        target.port = 28080;
      };
    };

    services.consul.services.lidarr = {
      port = 18686;

      checks.up = {
        http.path = "/";
        http.port = 8686;
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    ingress.virtualHosts.albums = {
      upstream = {
        service.name = "lidarr";
        tls.enable = true;
      };
    };

    cloover.backups.lidarr = {
      paths = [ dataDir ];
      exclude = [ "${dataDir}/logs" ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 ${dataDir}/lidarr.db ".backup '${dataDir}/lidarr-backup.db'"
      '';
      backupCleanupCommand = ''
        rm ${dataDir}/lidarr-backup.db
      '';
    };
  };
}
