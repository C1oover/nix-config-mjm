{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.server;
in
{
  config = mkIf (cfg.enable && cfg.enableAlloy) {
    services.alloy = {
      enable = true;
    };

    environment.etc."alloy/journal.alloy".source = ./journal.alloy;
    environment.etc."alloy/unix.alloy".source = ./unix.alloy;
    environment.etc."alloy/prometheus.alloy".source = ./prometheus.alloy;

    mjm.spire.tunnels = {
      alloy-loki = {
        mode = "client";
        port = 13101;
        target = "loki.service.consul:3103";
        service = "loki";
      };
      alloy-prometheus = {
        mode = "client";
        port = 13102;
        target = "prometheus.service.consul:9090";
        service = "prometheus";
      };
    };

    services.consul.services.alloy = {
      port = 12345;
      metrics.enable = true;

      checks.up = {
        http.path = "/-/healthy";
        intervalSeconds = 30;
      };
    };

    networking.firewall.allowedTCPPorts = [ 12345 ];
  };
}
