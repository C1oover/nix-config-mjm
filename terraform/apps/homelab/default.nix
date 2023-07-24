let
  name = "homelab";
  image = builtins.readFile ./image.txt;
in {
  nomad.jobs.homelab = {
    priority = 60;

    taskGroups.homelab = {
      architecture = "amd64";

      services = [
        {
          inherit name;
          port = 4000;
          connect.enable = true;
          metrics.enable = true;
          checks = [
            {
              http.path = "/healthz";
              interval = 10;
              timeout = 5;
            }
          ];
        }
      ];

      tasks.homelab = {
        docker = {inherit image;};
        env.OTEL_SERVICE_NAME = "homelab";
        env.OTEL_EXPORTER_OTLP_ENDPOINT = "http://$\${attr.unique.network.ip-address}:4318";
        cpu = 200;
        memory = 300;
        loggingTag = name;
        vault.policies = [name];

        templates."secrets/homelab.env" = {
          text = ''
            PAPERLESS_TOKEN={{ with secret "kv/paperless/client" }}{{ .Data.data.api_token }}{{ end }}
            {{ with secret "database/creds/homelab" }}
            DATABASE_URL=ecto://{{ .Data.username }}:{{ .Data.password }}@postgresql.service.consul/homelab
            {{ end }}
            {{ with secret "kv/homelab" -}}
            GITLAB_TOKEN={{ .Data.data.gitlab_token }}
            NETBOX_TOKEN={{ .Data.data.netbox_token }}
            SECRET_KEY_BASE={{ .Data.data.secret_key_base }}
            AWS_ACCESS_KEY_ID=deploy
            AWS_SECRET_ACCESS_KEY={{ .Data.data.minio_secret_key }}
            {{ end }}
          '';
          changeMode = "restart";
          envVars = true;
        };
      };
    };
  };

  vault.databases.roles.homelab = {
    ttl = "long";
  };
  vault.approles.roles.homelab = {};

  vault.policies.homelab.text = ''
    path "kv/data/homebase-bot" {
      capabilities = ["read"]
    }

    path "kv/data/paperless/client" {
      capabilities = ["read"]
    }

    path "kv/data/homelab" {
      capabilities = ["read"]
    }

    path "database/creds/homelab" {
      capabilities = ["read"]
    }

    path "kv/data/borg" {
      capabilities = ["read"]
    }

    path "kv/data/tarsnap" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.homelab = {
    upstream.service = {
      inherit name;
      connectPort = 4000;
    };
  };
}
