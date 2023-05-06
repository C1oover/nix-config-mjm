{ config
, pkgs
, ...
}:
let
  format = pkgs.formats.json { };
in
{
  services.promtail = {
    enable = true;
    configuration = {
      server.http_listen_port = 3101;
      clients = [
        { url = "http://loki.service.consul:3100/loki/api/v1/push"; }
      ];

      scrape_configs = [
        {
          job_name = "systemd-journal";
          journal = {
            labels.job = "default/systemd-journal";
            path = "/var/log/journal";
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "systemd_unit";
            }
            {
              source_labels = [ "__journal__hostname" ];
              target_label = "hostname";
            }
            {
              source_labels = [ "__journal_syslog_identifier" ];
              target_label = "syslog_identifier";
            }
          ];
        }
      ];
    };
  };

  services.consul.extraConfigFiles = [
    (toString (format.generate "promtail.json" {
      service = {
        name = "promtail";
        id = "promtail:${config.networking.hostName}";
        port = 3101;
        meta = {
          metrics_path = "/metrics";
        };

        checks = [
          {
            name = "promtail is ready";
            http = "http://localhost:3101/";
            interval = "30s";
            timeout = "5s";
          }
        ];
      };
    }))
  ];
}
