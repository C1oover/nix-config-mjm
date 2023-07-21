{config, ...}: {
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

      configuration = {
        global.resolve_timeout = "5m";

        templates = [
          ./templates/pagerduty.tpl
        ];

        route = {
          group_by = ["alertname" "severity"];
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
                routing_key_file = config.age.secrets."pagerduty-routing-key".path;
                severity = "{{ template \"pagerduty.severity\" . }}";
              }
            ];
          }
        ];

        inhibit_rules = [];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.port
  ];

  services.consul.services = {
    prometheus = let
      inherit (config.services.prometheus) port;
    in {
      inherit port;
      meta.metrics_path = "/metrics";

      checks = [
        {
          name = "prometheus is ready";
          http = "http://localhost:${toString port}/-/ready";
          interval = "30s";
          timeout = "5s";
        }
      ];
    };

    alertmanager = let
      inherit (config.services.prometheus.alertmanager) port;
    in {
      inherit port;
      meta.metrics_path = "/metrics";

      checks = [
        {
          name = "alertmanager is ready";
          http = "http://localhost:${toString port}/-/ready";
          interval = "30s";
          timeout = "5s";
        }
      ];
    };
  };

  age.secrets."pagerduty-routing-key".file = ../../../../secrets/pagerduty-routing-key.age;
}
