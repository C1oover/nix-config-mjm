{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.prometheus;
in
{
  options.mjm.prometheus = {
    enable = mkEnableOption "prometheus";
  };

  imports = [
    ./blackbox.nix
    ./consul-exporter.nix
    ./pve-exporter.nix
    ./jobs
  ];

  config = mkIf cfg.enable {
    mjm.services.prometheus = { };
    mjm.state.services = [ "prometheus" ];

    ingress.virtualHosts = {
      alerts = {
        upstream.service.name = "alertmanager";
      };

      metrics = {
        upstream.service.name = "prometheus";
      };
    };

    services.prometheus = {
      enable = true;
      checkConfig = "syntax-only";
      webExternalUrl = "https://metrics.midna.dev";

      globalConfig = {
        scrape_interval = "60s";
        evaluation_interval = "30s";
      };

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
        environmentFile = config.vault-secrets.templates.alertmanager-env.path;

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
                  routing_key = "$PAGERDUTY_ROUTING_KEY";
                  severity = ''{{ template "pagerduty.severity" . }}'';
                }
              ];
            }
          ];

          inhibit_rules = [ ];
        };
      };
    };

    vault.services.prometheus = { };
    vault-secrets.wantedBy = [ "alertmanager.service" ];
    vault-secrets.templates.alertmanager-env.text = ''
      {{ with secret "kv/prod/services/prometheus" }}
      PAGERDUTY_ROUTING_KEY={{ .Data.data.pagerduty_routing_key }}
      {{ end }}
    '';

    networking.firewall.allowedTCPPorts = [ config.services.prometheus.port ];

    services.consul.services = {
      prometheus = {
        inherit (config.services.prometheus) port;
        metrics.enable = true;

        checks.up = {
          http.path = "/-/ready";
          intervalSeconds = 30;
        };
      };

      alertmanager = {
        inherit (config.services.prometheus.alertmanager) port;
        metrics.enable = true;

        checks.up = {
          http.path = "/-/ready";
          intervalSeconds = 30;
        };
      };
    };
  };
}
