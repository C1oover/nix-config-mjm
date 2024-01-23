{ config, ... }:
{
  services.sabnzbd = {
    enable = true;
  };

  users.users.sabnzbd.extraGroups = [ "media" ];

  services.prometheus.exporters.sabnzbd = {
    enable = true;
    openFirewall = true;
    listenAddress = "::";
    servers = [
      {
        baseUrl = "http://localhost:8080/sabnzbd";
        apiKeyFile = config.age.secrets."sabnzbd-apikey".path;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];

  services.consul.services.sabnzbd = {
    port = 8080;

    meta = {
      metrics_path = "/metrics";
      metrics_port = toString config.services.prometheus.exporters.sabnzbd.port;
    };

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

  age.secrets."sabnzbd-apikey".file = ../../../secrets/sabnzbd-apikey.age;
}
