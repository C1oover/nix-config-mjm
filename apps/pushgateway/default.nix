let
  name = "pushgateway";
  # pushgateway 1.5.1
  image = "prom/pushgateway@sha256:28fe26c8b8b183ad6f6208936d678d875097b0635ffdffc41dfa734afd71ed17";
in {
  nomad.jobs.pushgateway = {
    priority = 70;

    taskGroups.pushgateway = {
      architecture = "arm64";

      ports.http = {};

      services = [
        {
          inherit name;
          port = "http";
          checks = [
            {
              http.path = "/-/ready";
              interval = 15;
              timeout = 3;
              successBeforePassing = 3;
            }
          ];
        }
      ];

      tasks.pushgateway = {
        docker = {
          inherit image;
          args = ["--web.listen-address=:$\${NOMAD_PORT_http}"];
        };
        ports = ["http"];
        cpu = 50;
        memory = 50;
        loggingTag = name;
      };
    };
  };
}
