{ pkgs, config, ... }:
{
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

  services.prometheus.exporters = {
    exportarr-sonarr = {
      enable = true;
      openFirewall = true;
      apiKeyFile = config.vault-secrets.templates.sonarr-api-key.path;
      url = "http://127.0.0.1:8989";
    };
    exportarr-radarr = {
      enable = true;
      port = 9707;
      openFirewall = true;
      apiKeyFile = config.vault-secrets.templates.radarr-api-key.path;
      url = "http://127.0.0.1:7878";
    };
    exportarr-readarr = {
      enable = true;
      port = 9706;
      openFirewall = true;
      apiKeyFile = config.vault-secrets.templates.readarr-api-key.path;
      url = "http://127.0.0.1:8787";
    };
  };

  vault-secrets.wantedBy = [
    "prometheus-exportarr-sonarr-exporter.service"
    "prometheus-exportarr-radarr-exporter.service"
    "prometheus-exportarr-readarr-exporter.service"
  ];
  vault-secrets.templates = {
    sonarr-api-key.kvPath = "kv/mediaserver/sonarr_api_key";
    radarr-api-key.kvPath = "kv/mediaserver/radarr_api_key";
    readarr-api-key.kvPath = "kv/mediaserver/readarr_api_key";
  };

  services.consul.services = {
    sonarr = {
      port = 8989;

      meta = {
        metrics_path = "/metrics";
        metrics_port = toString config.services.prometheus.exporters.exportarr-sonarr.port;
      };

      checks = [
        {
          name = "sonarr is ready";
          http = "http://localhost:8989/";
          interval = "15s";
          timeout = "10s";
          failures_before_warning = 2;
          failures_before_critical = 6;
        }
      ];
    };

    radarr = {
      port = 7878;

      meta = {
        metrics_path = "/metrics";
        metrics_port = toString config.services.prometheus.exporters.exportarr-radarr.port;
      };

      checks = [
        {
          name = "radarr is ready";
          http = "http://localhost:7878/";
          interval = "15s";
          timeout = "10s";
          failures_before_warning = 2;
          failures_before_critical = 6;
        }
      ];
    };

    readarr = {
      port = 8787;

      meta = {
        metrics_path = "/metrics";
        metrics_port = toString config.services.prometheus.exporters.exportarr-readarr.port;
      };

      checks = [
        {
          name = "readarr is ready";
          http = "http://localhost:8787/";
          interval = "15s";
          timeout = "10s";
          failures_before_warning = 2;
          failures_before_critical = 6;
        }
      ];
    };

    readarr-audio = {
      port = 8788;

      checks = [
        {
          name = "readarr is ready";
          http = "http://localhost:8788/";
          interval = "15s";
          timeout = "10s";
          failures_before_warning = 2;
          failures_before_critical = 6;
        }
      ];
    };
  };

  # ffprobe
  systemd.services.radarr.path = [ pkgs.ffmpeg ];
}
