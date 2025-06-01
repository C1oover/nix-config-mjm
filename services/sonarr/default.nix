{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cloover.sonarr;
in
{
  options.cloover.sonarr = {
    enable = mkEnableOption "Sonarr";
  };

  config = mkIf cfg.enable {
    cloover.services.sonarr = {
      vault.enable = true;
    };
    cloover.state.directories = [
      {
        directory = config.services.sonarr.dataDir;
        inherit (config.services.sonarr) user group;
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

    services.sonarr = {
      enable = true;
      settings.server.bindaddress = "localhost";
    };

    users.groups.media.gid = 997;
    users.users.sonarr.extraGroups = [ "media" ];

    systemd.tmpfiles.settings."10-sonarr" = {
      "/videos/shows" = {
        d = {
          user = "sonarr";
          group = "media";
        };
        Z = {
          user = "sonarr";
          group = "media";
          mode = "~0775";
        };
      };
    };

    services.prometheus.exporters.exportarr-sonarr = {
      enable = true;
      listenAddress = "::1";
      apiKeyFile = "/run/sonarr-creds.sock";
      url = "http://127.0.0.1:8989";
    };

    cloover.spire.creds = {
      sonarr.aliases = {
        "prometheus-exportarr-sonarr-exporter.service/api-key" = "sonarr/api_key";
      };
    };

    cloover.spire.tunnels = {
      sonarr = {
        id = "sonarr";
        mode = "server";
        listen.port = 18989;
        target.port = 8989;
        allowIngress = true;
      };
      sonarr-metrics = {
        id = "sonarr";
        mode = "server";
        listen.port = 19708;
        target.port = 9708;
        allowMetrics = true;
      };
      sonarr-sabnzbd = {
        id = "sonarr";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        target.service = "sabnzbd";
        target.port = 28080;
      };
    };

    services.consul.services.sonarr = {
      port = 18989;

      metrics.enable = true;
      metrics.port = 19708;
      metrics.tls = true;

      checks.up = {
        http.path = "/";
        http.port = 8989;
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    ingress.virtualHosts.tv = {
      upstream = {
        service.name = "sonarr";
        tls.enable = true;
      };
    };

    cloover.backups.sonarr = {
      paths = [ "/var/lib/sonarr/.config/NzbDrone" ];
      exclude = [ "/var/lib/sonarr/.config/NzbDrone/logs" ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/sonarr/.config/NzbDrone/sonarr.db ".backup '/var/lib/sonarr/.config/NzbDrone/sonarr-backup.db'"
      '';
      backupCleanupCommand = ''
        rm /var/lib/sonarr/.config/NzbDrone/sonarr-backup.db
      '';
    };
  };
}
