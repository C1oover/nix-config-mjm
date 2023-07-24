let
  name = "promtail";
  # promtail 2.8.2
  image = "grafana/promtail@sha256:762bc5be21174c50c636cf53e4c94bacf940488a803edb3e3018f6d0dd09df57";
in {
  nomad.jobs.promtail = {
    priority = 80;

    taskGroups.promtail = {
      architecture = "arm64";

      ports.syslog.static = 3102;

      services = [
        {
          inherit name;
          port = 3101;
          metrics.enable = true;
          connect = {
            enable = true;
            upstreams.loki = 3100;
          };

          checks = [
            {
              http.path = "/ready";
              interval = 15;
              timeout = 3;
            }
          ];
        }
        {
          inherit name;
          port = "syslog";
          tags = ["syslog"];
        }
      ];

      tasks.promtail = {
        docker = {
          inherit image;
          args = ["-config.file=$\${NOMAD_TASK_DIR}/promtail.yml"];
        };
        ports = ["syslog"];
        cpu = 200;
        memory = 100;
        loggingTag = name;

        templates."local/promtail.yml".source = ./promtail.yml;
      };
    };
  };
}
