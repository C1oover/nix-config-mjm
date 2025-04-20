{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.server;
in
{
  config = mkIf (cfg.enable && cfg.enablePromtail) {
    services.alloy = {
      enable = true;
    };

    environment.etc."alloy/journal.alloy".text = ''
      loki.source.journal "read" {
        forward_to = [loki.write.endpoint.receiver]
        relabel_rules = loki.relabel.journal.rules
      }

      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label = "systemd_unit"
        }
        rule {
          source_labels = ["__journal__systemd_unit"]
          regex = "(.*)\\.service"
          target_label = "service_name"
        }
        rule {
          source_labels = ["__journal__hostname"]
          target_label = "hostname"
        }
        rule {
          source_labels = ["__journal_syslog_identifier"]
          target_label = "syslog_identifier"
        }
      }

      loki.write "endpoint" {
        endpoint {
          url = "http://localhost:13101/loki/api/v1/push"
        }
      }
    '';

    mjm.spire.tunnels.alloy-loki = {
      mode = "client";
      port = 13101;
      target = "loki.service.consul:3103";
      service = "loki";
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
