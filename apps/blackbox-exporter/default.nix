let
  name = "blackbox-exporter";
  # blackbox-exporter v0.23.0
  image = "prom/blackbox-exporter@sha256:ca04aa9d90934a2a4d29861d1ebf0e9802e1119ae68690a461e7f6648f6967e2";
in {
  nomad.jobs.blackbox-exporter = {
    priority = 70;

    taskGroups.blackbox-exporter = {
      architecture = "arm64";

      ports.http.static = 9115;

      services = [
        {
          inherit name;
          port = "http";
        }
      ];

      tasks.blackbox-exporter = {
        docker = {
          inherit image;
          args = [
            "--config.file=$\${NOMAD_TASK_DIR}/blackbox.yml"
            "--web.listen-address=:$\${NOMAD_PORT_http}"
          ];
        };
        ports = ["http"];
        cpu = 100;
        memory = 50;
        loggingTag = name;

        templates."local/blackbox.yml".source = ./blackbox.yml;
        templates."local/ca.pem".text = ''
          {{ with secret "pki-homelab/issuer/default/json" -}}
          {{ .Data.certificate }}
          {{ end }}
        '';
      };
    };
  };
}
