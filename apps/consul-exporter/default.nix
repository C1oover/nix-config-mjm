let
  name = "consul-exporter";
  # consul-exporter 0.9.0
  image = "prom/consul-exporter@sha256:c33c1614328541d38da3992e6827f1f9c8ef0098d29a41f64b36393ef0741b15";
in
{
  nomad.jobs.consul-exporter = {
    priority = 70;

    taskGroups.consul-exporter = {
      architecture = "arm64";

      ports.http = { };

      services = [
        {
          inherit name;
          port = "http";
          metrics.enable = true;
        }
      ];

      tasks.consul-exporter = {
        docker = {
          inherit image;
          args = [
            "--web.listen-address=:$\${NOMAD_PORT_http}"
            "--consul.server=$\${attr.unique.network.ip-address}:8500"
          ];
        };
        ports = [ "http" ];
        cpu = 50;
        memory = 50;
        loggingTag = name;
      };
    };
  };
}
