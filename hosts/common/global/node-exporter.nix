{ config
, pkgs
, ...
}:
let
  format = pkgs.formats.json { };
in
{
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

  services.consul.extraConfigFiles = [
    (toString (format.generate "node-exporter.json" {
      service = {
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
      };
    }))
  ];
}
