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
      settings.server.bindaddress = "localhost";
    };
    systemd.services.sonarr.networkNamespace = "sonarr";
    users.users.sonarr.extraGroups = [ "media" ];

    services.radarr = {
      enable = true;
      settings.server.bindaddress = "localhost";
    };
    systemd.services.radarr.networkNamespace = "radarr";
    users.users.radarr.extraGroups = [ "media" ];

    services.lidarr = {
      enable = true;
      settings.server.bindaddress = "localhost";
    };
    systemd.services.lidarr.networkNamespace = "lidarr";
    users.users.lidarr.extraGroups = [ "media" ];

    services.readarr = {
      enable = true;
      settings.server.bindaddress = "localhost";
    };
    systemd.services.readarr.networkNamespace = "readarr";
    users.users.readarr.extraGroups = [ "media" ];

    systemd.services.readarr-audio = {
      description = "Readarr (second instance)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      networkNamespace = "readarr-audio";

      environment = {
        READARR__SERVER__BINDADDRESS = "localhost";
      };

      serviceConfig = {
        Type = "simple";
        User = "readarr";
        Group = "readarr";
        StateDirectory = "readarr-audio";
        ExecStart = "${pkgs.readarr}/bin/Readarr -nobrowser -data=/var/lib/readarr-audio";
        Restart = "on-failure";
      };
    };

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
        listenAddress = "::1";
        apiKeyFile = "/run/sonarr-creds.sock";
        url = "http://127.0.0.1:8989";
      };
      exportarr-radarr = {
        enable = true;
        listenAddress = "::1";
        apiKeyFile = "/run/radarr-creds.sock";
        url = "http://127.0.0.1:7878";
      };
      exportarr-readarr = {
        enable = true;
        listenAddress = "::1";
        apiKeyFile = "/run/readarr-creds.sock";
        url = "http://127.0.0.1:8787";
      };
    };
    systemd.services.prometheus-exportarr-sonarr-exporter.networkNamespace = "sonarr";
    systemd.services.prometheus-exportarr-radarr-exporter.networkNamespace = "radarr";
    systemd.services.prometheus-exportarr-readarr-exporter.networkNamespace = "readarr";

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

    mjm.spire.tunnels = {
      sonarr = {
        mode = "server";
        listen.port = 8989;
        target.port = 8989;
        target.namespace = "sonarr";
        allowIngress = true;
        allowConsul = true;
      };
      sonarr-metrics = {
        mode = "server";
        listen.port = 9708;
        target.port = 9708;
        target.namespace = "sonarr";
        allowMetrics = true;
      };
      sonarr-sabnzbd = {
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "sonarr";
        target.service = "sabnzbd";
        target.port = 8080;
      };
      consul-sonarr = {
        mode = "client";
        listen.socket = "/run/consul-checks/sonarr.sock";
        target.port = 8989;
        service = "sonarr";
      };

      radarr = {
        mode = "server";
        listen.port = 7878;
        target.port = 7878;
        target.namespace = "radarr";
        allowIngress = true;
        allowConsul = true;
      };
      radarr-metrics = {
        mode = "server";
        listen.port = 9707;
        target.port = 9708;
        target.namespace = "radarr";
        allowMetrics = true;
      };
      radarr-sabnzbd = {
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "radarr";
        target.service = "sabnzbd";
        target.port = 8080;
      };
      consul-radarr = {
        mode = "client";
        listen.socket = "/run/consul-checks/radarr.sock";
        target.port = 7878;
        service = "radarr";
      };

      lidarr = {
        mode = "server";
        listen.port = 8686;
        target.port = 8686;
        target.namespace = "lidarr";
        allowIngress = true;
        allowConsul = true;
      };
      lidarr-sabnzbd = {
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "lidarr";
        target.service = "sabnzbd";
        target.port = 8080;
      };
      consul-lidarr = {
        mode = "client";
        listen.socket = "/run/consul-checks/lidarr.sock";
        target.port = 8686;
        service = "lidarr";
      };

      readarr = {
        mode = "server";
        listen.port = 8787;
        target.port = 8787;
        target.namespace = "readarr";
        allowIngress = true;
        allowConsul = true;
      };
      readarr-metrics = {
        mode = "server";
        listen.port = 9706;
        target.port = 9708;
        target.namespace = "readarr";
        allowMetrics = true;
      };
      readarr-sabnzbd = {
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "readarr";
        target.service = "sabnzbd";
        target.port = 8080;
      };
      consul-readarr = {
        mode = "client";
        listen.socket = "/run/consul-checks/readarr.sock";
        target.port = 8787;
        service = "readarr";
      };

      readarr-audio = {
        mode = "server";
        listen.port = 8788;
        target.port = 8788;
        target.namespace = "readarr-audio";
        allowIngress = true;
        allowConsul = true;
      };
      readarr-audio-sabnzbd = {
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "readarr-audio";
        target.service = "sabnzbd";
        target.port = 8080;
      };
      consul-readarr-audio = {
        mode = "client";
        listen.socket = "/run/consul-checks/readarr-audio.sock";
        target.port = 8788;
        service = "readarr-audio";
      };
    };

    services.consul.services = {
      sonarr = {
        port = 8989;

        metrics.enable = true;
        metrics.port = 9708;
        metrics.tls = true;

        checks.up = {
          http.path = "/";
          http.socket = "/run/consul-checks/sonarr.sock";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };

      radarr = {
        port = 7878;

        metrics.enable = true;
        metrics.port = 9707;
        metrics.tls = true;

        checks.up = {
          http.path = "/";
          http.socket = "/run/consul-checks/radarr.sock";
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
          http.socket = "/run/consul-checks/lidarr.sock";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };

      readarr = {
        port = 8787;

        metrics.enable = true;
        metrics.port = 9706;
        metrics.tls = true;

        checks.up = {
          http.path = "/";
          http.socket = "/run/consul-checks/readarr.sock";
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
          http.socket = "/run/consul-checks/readarr-audio.sock";
          checkConfig = {
            failures_before_warning = 2;
            failures_before_critical = 6;
          };
        };
      };
    };

    ingress.virtualHosts = {
      tv = {
        upstream = {
          service.name = "sonarr";
          tls.enable = true;
        };
      };
      movies = {
        upstream = {
          service.name = "radarr";
          tls.enable = true;
        };
      };
      albums = {
        upstream = {
          service.name = "lidarr";
          tls.enable = true;
        };
      };
      books = {
        upstream = {
          service.name = "readarr";
          tls.enable = true;
        };
      };
      audiobooks = {
        upstream = {
          service.name = "readarr-audio";
          tls.enable = true;
        };
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
