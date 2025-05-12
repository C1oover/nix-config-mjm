{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.mjm.alertmanager;
in
{
  options.mjm.alertmanager = {
    enable = mkEnableOption "Alertmanager";
  };

  config = mkIf cfg.enable {
    mjm.services.alertmanager = {
      vault.enable = true;
    };

    ingress.virtualHosts.alerts = {
      upstream = {
        service.name = "alertmanager";
        tls.enable = true;
      };
    };

    services.prometheus.alertmanager = {
      enable = true;
      listenAddress = "[::1]";
      port = 19093;
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
                details.firing = ''{{ template "pagerduty.instances" .Alerts.Firing }}'';
                details.resolved = ''{{ template "pagerduty.instances" .Alerts.Resolved }}'';
              }
            ];
          }
        ];

        inhibit_rules = [ ];
      };
    };

    systemd.services.alertmanager = {
      serviceConfig.LoadCredential = [
        "alertmanager_pagerduty_routing_key:/run/alertmanager-creds.sock"
      ];
    };

    mjm.spire.tunnels = {
      alertmanager = {
        mode = "server";
        listen.port = 9093;
        target.port = 19093;
        allowIngress = true;
        allowConsul = true;
        allowedServices = [
          "grafana"
          "loki"
          "prometheus"
          "launchpad"
        ];
      };
    };

    services.consul.services.alertmanager = {
      port = 9093;
      metrics.enable = true;
      metrics.tls = true;

      checks.up = {
        http.path = "/-/ready";
        http.port = 19093;
        intervalSeconds = 30;
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests.prometheus) alertmanager;
    };
  };
}
