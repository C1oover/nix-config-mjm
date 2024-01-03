{lib, ...}: let
  name = "grafana";
  image = "grafana/grafana-oss:10.2.3";
in {
  nomad.jobs.grafana = {
    priority = 70;

    taskGroups.grafana = {
      count = 3;
      architecture = "arm64";

      services = [
        {
          inherit name;
          port = 3000;
          connect = {
            enable = true;
            upstreams.loki = 3100;
          };
          metrics.enable = true;

          checks = [
            {
              http.path = "/api/health";
              interval = 15;
              timeout = 3;
            }
          ];
        }
      ];

      tasks.grafana = {
        docker = {inherit image;};
        env.GF_PATHS_CONFIG = "$\${NOMAD_SECRETS_DIR}/grafana.ini";
        env.GF_PATHS_PROVISIONING = "$\${NOMAD_TASK_DIR}/provisioning";
        cpu = 200;
        memory = 200;
        loggingTag = name;
        vault.policies = [name];

        templates =
          {
            "secrets/grafana.ini" = {
              source = ./grafana.ini;
              changeMode = "restart";
            };
            "local/provisioning/dashboards/dashboards.yaml" = {
              source = ./dashboards.yaml;
              changeMode = "restart";
            };
            "local/provisioning/datasources/datasources.yaml" = {
              source = ./datasources.yaml;
              changeMode = "restart";
            };
          }
          // (lib.attrsets.mapAttrs'
            (filename: _kind: {
              name = "local/dashboards/${filename}";
              value = {
                source = ./dashboards/${filename};
                leftDelimiter = "do_not_substitute";
              };
            })
            (builtins.readDir ./dashboards));
      };
    };
  };

  vault.databases.roles.grafana = {
    roleName = "grafana_user";
    ttl = "short";
  };

  vault.policies.grafana.text = ''
    # Allow grafana to read credentials for accessing its database
    path "database/creds/grafana" {
      capabilities = ["read"]
    }

    # Allow grafana to read the auth token for Fly.io to connect to Prometheus
    path "kv/data/grafana" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.grafana = {
    upstream.service = {
      inherit name;
      connectPort = 3000;
    };
  };
}
