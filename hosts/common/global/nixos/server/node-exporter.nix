{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.server;
in
{
  config = mkIf (cfg.enable && cfg.enableNodeExporter) {
    services.prometheus.exporters.node = {
      enable = true;
      openFirewall = true;
      enabledCollectors = [
        "processes"
        "systemd"
      ];
      extraFlags = [
        "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|nix/store|var/lib/docker/.+|run|run/.+|snap/.+)($|/)"
        "--collector.netclass.ignored-devices=^(veth|docker)"
        "--collector.netdev.device-exclude=^(veth|docker)"
      ];
    };

    services.consul.services.node-exporter =
      let
        inherit (config.services.prometheus.exporters.node) port;
      in
      {
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
  };
}
