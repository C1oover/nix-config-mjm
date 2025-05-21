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
      radarr.vault = {
        enable = true;
      };
      readarr.vault = {
        enable = true;
      };
    };
    mjm.state.directories = [
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
    systemd.services.prometheus-exportarr-radarr-exporter.networkNamespace = "radarr";
    systemd.services.prometheus-exportarr-readarr-exporter.networkNamespace = "readarr";

    mjm.spire.creds = {
      radarr.aliases = {
        "prometheus-exportarr-radarr-exporter.service/api-key" = "radarr/api_key";
      };
      readarr.aliases = {
        "prometheus-exportarr-readarr-exporter.service/api-key" = "readarr/api_key";
      };
    };

    mjm.spire.tunnels = {
      radarr = {
        id = "radarr";
        mode = "server";
        listen.port = 7878;
        target.port = 7878;
        target.namespace = "radarr";
        allowIngress = true;
        allowConsul = true;
      };
      radarr-metrics = {
        id = "radarr";
        mode = "server";
        listen.port = 9707;
        target.port = 9708;
        target.namespace = "radarr";
        allowMetrics = true;
      };
      radarr-sabnzbd = {
        id = "radarr";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "radarr";
        target.service = "sabnzbd";
        target.port = 28080;
      };
      consul-radarr = {
        id = "consul-agent";
        mode = "client";
        listen.socket = "/run/consul-checks/radarr.sock";
        target.port = 7878;
        service = "radarr";
      };

      lidarr = {
        id = "lidarr";
        mode = "server";
        listen.port = 8686;
        target.port = 8686;
        target.namespace = "lidarr";
        allowIngress = true;
        allowConsul = true;
      };
      lidarr-sabnzbd = {
        id = "lidarr";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "lidarr";
        target.service = "sabnzbd";
        target.port = 28080;
      };
      consul-lidarr = {
        id = "consul-agent";
        mode = "client";
        listen.socket = "/run/consul-checks/lidarr.sock";
        target.port = 8686;
        service = "lidarr";
      };

      readarr = {
        id = "readarr";
        mode = "server";
        listen.port = 8787;
        target.port = 8787;
        target.namespace = "readarr";
        allowIngress = true;
        allowConsul = true;
      };
      readarr-metrics = {
        id = "readarr";
        mode = "server";
        listen.port = 9706;
        target.port = 9708;
        target.namespace = "readarr";
        allowMetrics = true;
      };
      readarr-sabnzbd = {
        id = "readarr";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "readarr";
        target.service = "sabnzbd";
        target.port = 28080;
      };
      consul-readarr = {
        id = "consul-agent";
        mode = "client";
        listen.socket = "/run/consul-checks/readarr.sock";
        target.port = 8787;
        service = "readarr";
      };

      readarr-audio = {
        id = "readarr-audio";
        mode = "server";
        listen.port = 8788;
        target.port = 8788;
        target.namespace = "readarr-audio";
        allowIngress = true;
        allowConsul = true;
      };
      readarr-audio-sabnzbd = {
        id = "readarr-audio";
        mode = "client";
        listen.address = "127.0.0.1:8080";
        listen.namespace = "readarr-audio";
        target.service = "sabnzbd";
        target.port = 28080;
      };
      consul-readarr-audio = {
        id = "consul-agent";
        mode = "client";
        listen.socket = "/run/consul-checks/readarr-audio.sock";
        target.port = 8788;
        service = "readarr-audio";
      };
    };

    mjm.services.consul-agent = { };

    services.consul.services = {
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
        "/var/lib/radarr/.config/Radarr"
        "/var/lib/readarr"
      ];
      exclude = [
        "/var/lib/radarr/.config/Radarr/logs"
        "/var/lib/readarr/logs"
      ];
      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/radarr/.config/Radarr/radarr.db ".backup '/var/lib/radarr/.config/Radarr/radarr-backup.db'"
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/readarr/readarr.db ".backup '/var/lib/readarr/readarr-backup.db'"
      '';
      backupCleanupCommand = ''
        rm /var/lib/radarr/.config/Radarr/radarr-backup.db
        rm /var/lib/readarr/readarr-backup.db
      '';
    };
  };
}
