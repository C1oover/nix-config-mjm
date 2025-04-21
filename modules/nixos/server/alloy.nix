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
    environment.etc."alloy/otel.alloy".source = ./otel.alloy;

    mjm.spire.tunnels = {
      alloy-otlphttp = {
        mode = "server";
        listen.socket = "/run/alloy-otlphttp.sock";
        target.port = 4318;
      };
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
      alloy-tempo = {
        mode = "client";
        listen.port = 15317;
        target.service = "tempo";
        target.port = 14317;
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
