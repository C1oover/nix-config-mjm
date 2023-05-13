{ config, ... }: {
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

  age.secrets."alertmanager.env".file = ../../../../secrets/alertmanager-env.age;
}
