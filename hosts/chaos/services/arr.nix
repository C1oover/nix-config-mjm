{
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  services.consul.services.sonarr = {
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
}
