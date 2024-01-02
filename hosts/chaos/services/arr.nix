{pkgs, ...}: {
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

  services.consul.services = {
    sonarr = {
      port = 8989;

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
}
