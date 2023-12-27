{
  services.sabnzbd = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [8080];

  services.consul.services.sabnzbd = {
    port = 8080;

    checks = [
      {
        name = "sabnzbd is ready";
        http = "http://localhost:8080/";
        interval = "15s";
        timeout = "10s";
        failures_before_warning = 2;
        failures_before_critical = 6;
      }
    ];
  };
}
