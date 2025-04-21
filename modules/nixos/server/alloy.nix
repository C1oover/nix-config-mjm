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
        listen.port = 13101;
        target.service = "loki";
        target.port = 3103;
      };
      alloy-prometheus = {
        mode = "client";
        listen.port = 13102;
        target.service = "prometheus";
        target.port = 9090;
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
