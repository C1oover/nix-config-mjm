{
  pkgs,
  config,
  ...
}: {
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.sonarr.extraGroups = ["media"];

  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.radarr.extraGroups = ["media"];

  services.prometheus.exporters = {
    exportarr-sonarr = {
      enable = true;
      openFirewall = true;
      apiKeyFile = config.age.secrets."sonarr-apikey".path;
      url = "http://127.0.0.1:8989";
    };
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
  };

  # ffprobe
  systemd.services.radarr.path = [pkgs.ffmpeg];

  age.secrets = {
    "sonarr-apikey".file = ../../../secrets/sonarr-apikey.age;
  };
}
