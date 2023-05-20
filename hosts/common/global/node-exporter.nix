{config, ...}: {
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    enabledCollectors = [
      "processes"
      "systemd"
    ];
    extraFlags = [
      "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|nix/store|var/lib/docker/.+|var/lib/nomad/.+|run|run/.+|snap/.+)($|/)"
      "--collector.netclass.ignored-devices=^(veth|docker|nomad)"
      "--collector.netdev.device-exclude=^(veth|docker|nomad)"
    ];
  };

  services.consul.services.node-exporter = let
    inherit (config.services.prometheus.exporters.node) port;
  in {
    inherit port;
    meta.metrics_path = "/metrics";

    checks = [
      {
        name = "node-exporter HTTP";
        http = "http://localhost:${toString port}/";
        interval = "30s";
        timeout = "5s";
      }
    ];
  };
}
