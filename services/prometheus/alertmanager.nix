{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.mjm.prometheus;
in
{
  config = mkIf cfg.enable {
    mjm.services.alertmanager = {
      vault = {
        enable = true;
        useSpiffeIdentity = true;
      };
    };

    ingress.virtualHosts.alerts = {
      upstream = {
        service.name = "alertmanager";
        tls.enable = true;
      };
    };

    services.prometheus = {
      alertmanagers = [
        {
          static_configs = [
            { targets = [ "localhost:9093" ]; }
          ];
        }
      ];

      alertmanager = {
        enable = true;
        listenAddress = "[::1]";
        port = 9093;
        webExternalUrl = "https://alerts.midna.dev";

        configuration = {
          global.resolve_timeout = "5m";

          templates = [ ./templates/pagerduty.tpl ];

          route = {
            group_by = [
              "alertname"
              "severity"
            ];
            group_wait = "10s";
            group_interval = "10s";
            repeat_interval = "1h";
            receiver = "pagerduty";
          };

          receivers = [
            {
              name = "pagerduty";
              pagerduty_configs = [
                {
                  routing_key_file = "\${CREDENTIALS_DIRECTORY}/alertmanager_pagerduty_routing_key";
                  severity = ''{{ template "pagerduty.severity" . }}'';
                }
              ];
            }
          ];

          inhibit_rules = [ ];
        };
      };
    };

    systemd.services.alertmanager = {
      bindsTo = [ "netns-bridge@alertmanager.service" ];
      after = [ "netns-bridge@alertmanager.service" ];
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/alertmanager";
        LoadCredential = [
          "alertmanager_pagerduty_routing_key:/run/alertmanager-creds.sock"
        ];
      };
    };

    mjm.spire.tunnels = {
      alertmanager = {
        mode = "server";
        namespace = "alertmanager";
        port = 9093;
        target = "localhost:9093";
        allowIngress = true;
        allowedServices = [
          "grafana"
          "prometheus"
          "consul-agent"
        ];
      };
      prometheus-alertmanager = {
        mode = "client";
        namespace = "prometheus";
        port = 9093;
        target = "alertmanager.service.consul:9093";
        service = "alertmanager";
      };
      consul-alertmanager = {
        mode = "client";
        socket = "/run/consul-checks/alertmanager.sock";
        target = "localhost:9093";
        service = "alertmanager";
      };
    };

    services.consul.services.alertmanager = {
      port = 9093;
      metrics.enable = true;
      metrics.tls = true;

      checks.up = {
        http.path = "/-/ready";
        http.socket = "/run/consul-checks/alertmanager.sock";
        intervalSeconds = 30;
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests.prometheus) alertmanager;
    };
  };
}
