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
      upstream.service.name = "alertmanager";
    };

    services.prometheus = {
      alertmanagers = [
        {
          static_configs = [
            { targets = [ "127.0.0.1:${toString config.services.prometheus.alertmanager.port}" ]; }
          ];
        }
      ];

      alertmanager = {
        enable = true;
        openFirewall = true;
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

    systemd.services.alertmanager.serviceConfig.LoadCredential = [
      "alertmanager_pagerduty_routing_key:/run/alertmanager-creds.sock"
    ];

    services.consul.services.alertmanager = {
      inherit (config.services.prometheus.alertmanager) port;
      metrics.enable = true;

      checks.up = {
        http.path = "/-/ready";
        intervalSeconds = 30;
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests.prometheus) alertmanager;
    };
  };
}
