let
  name = "pve-exporter";
  # pve-exporter 2.3.0
  image = "prompve/prometheus-pve-exporter@sha256:c38a29b0fd0b8f776cc2770cfe844fc577b28e9be467626824053cfa6080624d";
in {
  nomad.jobs.pve-exporter = {
    priority = 70;

    taskGroups.pve-exporter = {
      architecture = "amd64";

      ports.http.static = 9221;

      services = [
        {
          inherit name;
          port = "http";

          checks = [
            {
              http.path = "/";
              interval = 15;
              timeout = 3;
            }
          ];
        }
      ];

      tasks.pve-exporter = {
        docker = {
          inherit image;
          args = [
            "$\${NOMAD_SECRETS_DIR}/pve.yml"
            "$\${NOMAD_PORT_http}"
            "0.0.0.0"
          ];
        };
        ports = ["http"];
        cpu = 100;
        memory = 100;
        loggingTag = name;
        vault.policies = [name];

        templates."secrets/pve.yml".source = ./pve.yml;
      };
    };
  };

  vault.policies.pve-exporter.text = ''
    path "kv/data/proxmox" {
      capabilities = ["read"]
    }
  '';
}
