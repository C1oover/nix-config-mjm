{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.radarr;
in
{
  options.mjm.radarr = {
    enable = mkEnableOption "Radarr";
  };

  config = mkIf cfg.enable {
    mjm.services.radarr = {
      vault.enable = true;
    };
    mjm.state.directories = [
      {
        directory = config.services.radarr.dataDir;
        inherit (config.services.radarr) user group;
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

    services.radarr = {
      enable = true;
      settings.server.bindaddress = "localhost";
    };

    users.groups.media.gid = 997;
    users.users.radarr.extraGroups = [ "media" ];

    systemd.tmpfiles.settings."10-radarr" = {
      "/videos/movies" = {
        d = {
          user = "radarr";
          group = "media";
        };
        Z = {
          user = "radarr";
          group = "media";
          mode = "~0775";
        };
      };
    };

    services.prometheus.exporters.exportarr-radarr = {
      enable = true;
      listenAddress = "::1";
      apiKeyFile = "/run/radarr-creds.sock";
      url = "http://127.0.0.1:7878";
    };

    mjm.spire.creds = {
      radarr.aliases = {
        "prometheus-exportarr-radarr-exporter.service/api-key" = "radarr/api_key";
      };
    };

    mjm.spire.tunnels = {
      radarr = {
        id = "radarr";
        mode = "server";
        listen.port = 17878;
        target.port = 7878;
        allowIngress = true;
      };
      radarr-metrics = {
        id = "radarr";
        mode = "server";
        listen.port = 19708;
        target.port = 9708;
        allowMetrics = true;
      };
      radarr-sabnzbd = {
        id = "radarr";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        target.service = "sabnzbd";
        target.port = 28080;
      };
    };

    services.consul.services.radarr = {
      port = 17878;

      metrics.enable = true;
      metrics.port = 19708;
      metrics.tls = true;

      checks.up = {
        http.path = "/";
        http.port = 7878;
        checkConfig = {
          failures_before_warning = 2;
          failures_before_critical = 6;
        };
      };
    };

    ingress.virtualHosts.movies = {
      upstream = {
        service.name = "radarr";
        tls.enable = true;
      };
    };

    # ffprobe
    systemd.services.radarr.path = [ pkgs.ffmpeg ];

    # TODO backup radarr content in its own backup repo
    # mjm.backups.radarr = {
    #   paths = [ "/var/lib/radarr/.config/Radarr" ];
    #   exclude = [ "/var/lib/radarr/.config/Radarr/logs" ];
    #   backupPrepareCommand = ''
    #     ${pkgs.sqlite}/bin/sqlite3 /var/lib/radarr/.config/Radarr/radarr.db ".backup '/var/lib/radarr/.config/Radarr/radarr-backup.db'"
    #   '';
    #   backupCleanupCommand = ''
    #     rm /var/lib/radarr/.config/Radarr/radarr-backup.db
    #   '';
    # };
  };
}
