let
  name = "nut";
  # nut-exporter 3.0.0
  image = "ghcr.io/druggeri/nut_exporter@sha256:af8ede95b5798d78985fb24905184aa7b19c5684a6347841799062bf1e2c8f75";

  enabledVariables = [
    "battery.charge"
    "battery.runtime"
    "battery.voltage"
    "battery.voltage.nominal"
    "input.voltage"
    "input.voltage.nominal"
    "ups.load"
    "ups.status"
  ];
in {
  nomad.jobs.nut = {
    priority = 70;

    taskGroups.nut = {
      architecture = "arm64";

      ports.metrics.to = 9199;

      services = [
        {
          inherit name;
          port = "metrics";
          metrics.enable = true;
          metrics.path = "/ups_metrics";

          checks = [
            {
              http.path = "/";
              interval = 30;
              timeout = 5;
            }
          ];
        }
      ];

      tasks.nut-exporter = {
        docker = {
          inherit image;
          args = [
            "--nut.server=10.0.0.2"
            "--nut.vars_enable=${builtins.concatStringsSep "," enabledVariables}"
          ];
        };
        ports = ["metrics"];
        cpu = 50;
        memory = 50;
        loggingTag = name;
      };
    };
  };
}
