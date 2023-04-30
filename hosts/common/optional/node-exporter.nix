{ config, ... }: {
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    enabledCollectors = [
      "processes"
      "systemd"
    ];
  };

  services.consul.extraConfig.services = [
    {
      name = "node-exporter";
      id = "node-exporter:${config.networking.hostName}";
      port = config.services.prometheus.exporters.node.port;
      meta = {
        metrics_path = "/metrics";
      };

      checks = [
        {
          name = "node-exporter HTTP";
          http = "http://localhost:${toString config.services.prometheus.exporters.node.port}/";
          interval = "30s";
          timeout = "5s";
        }
      ];
    }
  ];
}
