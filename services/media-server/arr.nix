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
    mjm.services = {
      sonarr.vault = {
        enable = true;
      };
      radarr.vault = {
        enable = true;
      };
      readarr.vault = {
        enable = true;
      };
    };
    mjm.state.directories = [
      {
        directory = config.services.sonarr.dataDir;
        inherit (config.services.sonarr) user group;
      }
      {
        directory = config.services.radarr.dataDir;
        inherit (config.services.radarr) user group;
      }
      {
        directory = config.services.lidarr.dataDir;
        inherit (config.services.lidarr) user group;
      }
      {
        directory = config.services.readarr.dataDir;
        inherit (config.services.readarr) user group;
      }
      {
        directory = "/var/lib/readarr-audio";
        user = "readarr";
        group = "readarr";
      }
    ];

    services.sonarr = {
      enable = true;
      openFirewall = true;
    };
    users.users.sonarr.extraGroups = [ "media" ];

    services.radarr = {
      enable = true;
      openFirewall = true;
    };
    users.users.radarr.extraGroups = [ "media" ];

    services.lidarr = {
      enable = true;
      openFirewall = true;
    };
    users.users.lidarr.extraGroups = [ "media" ];

    services.readarr = {
      enable = true;
      openFirewall = true;
    };
    users.users.readarr.extraGroups = [ "media" ];

    systemd.services.readarr-audio = {
      description = "Readarr (second instance)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "readarr";
        Group = "readarr";
        StateDirectory = "readarr-audio";
        ExecStart = "${pkgs.readarr}/bin/Readarr -nobrowser -data=/var/lib/readarr-audio";
        Restart = "on-failure";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8788 ];

    systemd.tmpfiles.settings."10-media-server" = {
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
      "/videos/books" = {
        d = {
          user = "readarr";
          group = "media";
        };
        Z = {
          user = "readarr";
          group = "media";
          mode = "~0775";
        };
      };
      "/videos/audiobooks" = {
        d = {
          user = "readarr";
          group = "media";
        };
        Z = {
          user = "readarr";
          group = "media";
          mode = "~0775";
        };
      };
    };

    services.prometheus.exporters = {
      exportarr-sonarr = {
        enable = true;
        openFirewall = true;
        apiKeyFile = "/run/sonarr-creds.sock";
        url = "http://127.0.0.1:8989";
      };
      exportarr-radarr = {
        enable = true;
        port = 9707;
        openFirewall = true;
        apiKeyFile = "/run/radarr-creds.sock";
        url = "http://127.0.0.1:7878";
      };
      exportarr-readarr = {
        enable = true;
        port = 9706;
        openFirewall = true;
        apiKeyFile = "/run/readarr-creds.sock";
        url = "http://127.0.0.1:8787";
      };
    };

    mjm.spire.creds = {
      sonarr.aliases = {
        "prometheus-exportarr-sonarr-exporter.service/api-key" = "sonarr/api_key";
      };
      radarr.aliases = {
        "prometheus-exportarr-radarr-exporter.service/api-key" = "radarr/api_key";
      };
      readarr.aliases = {
        "prometheus-exportarr-readarr-exporter.service/api-key" = "readarr/api_key";
      };
    };

    services.consul.services = {
      sonarr = {
        port = 8989;

        metrics.enable = true;
        metrics.port = config.services.prometheus.exporters.exportarr-sonarr.port;

        checks.up = {
          http.path = "/";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };

      radarr = {
        port = 7878;

        metrics.enable = true;
        metrics.port = config.services.prometheus.exporters.exportarr-radarr.port;

        checks.up = {
          http.path = "/";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };

      lidarr = {
        port = 8686;

        checks.up = {
          http.path = "/";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };

      readarr = {
        port = 8787;

        metrics.enable = true;
        metrics.port = config.services.prometheus.exporters.exportarr-readarr.port;

        checks.up = {
          http.path = "/";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };

      readarr-audio = {
        port = 8788;

        checks.up = {
          http.path = "/";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };
    };

    ingress.virtualHosts = {
      tv = {
        upstream.service.name = "sonarr";
      };
      movies = {
        upstream.service.name = "radarr";
      };
      albums = {
        upstream.service.name = "lidarr";
      };
      books = {
        upstream.service.name = "readarr";
      };
      audiobooks = {
        upstream.service.name = "readarr-audio";
      };
    };

    # ffprobe
    systemd.services.radarr.path = [ pkgs.ffmpeg ];

    # TODO add lidarr
    mjm.backups.media-server = {
      paths = [
        "/var/lib/sonarr/.config/NzbDrone"
        "/var/lib/radarr/.config/Radarr"
        "/var/lib/readarr"
      ];
      exclude = [
        "/var/lib/sonarr/.config/NzbDrone/logs"
        "/var/lib/radarr/.config/Radarr/logs"
        "/var/lib/readarr/logs"
      ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/sonarr/.config/NzbDrone/sonarr.db ".backup '/var/lib/sonarr/.config/NzbDrone/sonarr-backup.db'"
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/radarr/.config/Radarr/radarr.db ".backup '/var/lib/radarr/.config/Radarr/radarr-backup.db'"
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/readarr/readarr.db ".backup '/var/lib/readarr/readarr-backup.db'"
      '';
      backupCleanupCommand = ''
        rm /var/lib/sonarr/.config/NzbDrone/sonarr-backup.db
        rm /var/lib/radarr/.config/Radarr/radarr-backup.db
        rm /var/lib/readarr/readarr-backup.db
      '';
    };
  };
}
