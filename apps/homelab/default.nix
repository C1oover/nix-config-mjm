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
        env.TASKRC = "$\${NOMAD_TASK_DIR}/taskrc";
        # letting this get set automatically breaks on Docker 24:
        # https://elixirforum.com/t/elixir-erlang-docker-containers-ram-usage-on-different-oss-kernels/57251/18
        env.ERL_MAX_PORTS = "65536";
        cpu = 500;
        memory = 500;
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

        templates."secrets/task.key" = {
          text = ''
            {{ with secret "kv/taskwarrior" }}{{ .Data.data.private_key }}{{ end }}
          '';
          changeMode = "noop";
        };

        templates."local/task.crt" = {
          source = ../../home/matt/features/taskwarrior/cert.crt;
          changeMode = "noop";
        };
        templates."local/task.ca" = {
          source = ../../home/matt/features/taskwarrior/ca.crt;
          changeMode = "noop";
        };

        templates."local/taskrc" = {
          text = ''
            data.location={{ env "NOMAD_TASK_DIR" }}
            taskd.ca={{ env "NOMAD_TASK_DIR" }}/task.ca
            taskd.certificate={{ env "NOMAD_TASK_DIR" }}/task.crt
            taskd.credentials=home/mjm/158e73c7-9492-44cb-b340-508633b860f2
            taskd.key={{ env "NOMAD_SECRETS_DIR" }}/task.key
            taskd.server=nemesis.home.mattmoriarity.com:53589

            uda.reminder_id.type=string
            uda.reminder_id.label=Reminder
            uda.next_notification.type=date
            uda.next_notification.label=Notify
          '';
          changeMode = "noop";
        };
      };
    };
  };

  vault.databases.roles.homelab = {
    ttl = "long";
  };

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

    path "kv/data/taskwarrior" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.home = {
    upstream.service = {
      inherit name;
      connectPort = 4000;
    };
    external = true;
  };
}
