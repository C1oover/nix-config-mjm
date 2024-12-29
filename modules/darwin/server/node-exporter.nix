{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.server;
in
{
  options.mjm.server.enableNodeExporter = mkOption {
    type = types.bool;
    default = true;
    description = "Whether to enable the Prometheus node-exporter";
  };

  config = mkIf (cfg.enable && cfg.enableNodeExporter) {
    services.prometheus.exporters.node = {
      enable = true;
      disabledCollectors = [ "thermal" ];
    };

    services.consul.services.node-exporter = {
      inherit (config.services.prometheus.exporters.node) port;
      metrics.enable = true;

      checks.up = {
        http.path = "/";
        intervalSeconds = 30;
      };
    };
  };
}
