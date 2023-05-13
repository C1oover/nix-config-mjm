{ config
, pkgs
, ...
}:
let
  format = pkgs.formats.json { };
in
{
  imports = [
    ./jobs
    ./rules
  ];

  services.prometheus = {
    enable = true;
    checkConfig = "syntax-only";
    webExternalUrl = "https://prometheus.home.mattmoriarity.com";

    globalConfig = {
      scrape_interval = "60s";
      evaluation_interval = "30s";
    };

    alertmanagers = [
      {
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.alertmanager.port}"
            ];
          }
        ];
      }
    ];

    alertmanager = {
      enable = true;
      openFirewall = true;
      webExternalUrl = "https://alertmanager.home.mattmoriarity.com";
      environmentFile = config.age.secrets."alertmanager.env".path;

      configuration = {
        global.resolve_timeout = "5m";

        templates = [
          ./templates/pagerduty.tpl
        ];

        route = {
          group_by = [ "alertname" "severity" ];
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
                severity = "{{ template \"pagerduty.severity\" . }}";
              }
            ];
          }
        ];

        inhibit_rules = [ ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.port
  ];

  services.consul.extraConfigFiles = [
    (toString (format.generate "prometheus.json" {
      service = {
        name = "prometheus";
        id = "prometheus:${config.networking.hostName}";
        port = config.services.prometheus.port;

        meta.metrics_path = "/metrics";

        checks = [
          {
            name = "prometheus is ready";
            http = "http://localhost:${toString config.services.prometheus.port}/-/ready";
            interval = "30s";
            timeout = "5s";
          }
        ];
      };
    }))
    (toString (format.generate "alertmanager.json" {
      service = {
        name = "alertmanager";
        id = "alertmanager:${config.networking.hostName}";
        port = config.services.prometheus.alertmanager.port;

        meta.metrics_path = "/metrics";

        checks = [
          {
            name = "alertmanager is ready";
            http = "http://localhost:${toString config.services.prometheus.alertmanager.port}/-/ready";
            interval = "30s";
            timeout = "5s";
          }
        ];
      };
    }))
  ];

  age.secrets."alertmanager.env".file = ../../../../secrets/alertmanager-env.age;
}
