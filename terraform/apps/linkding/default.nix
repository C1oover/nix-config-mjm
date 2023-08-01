let
  name = "linkding";
  # linkding 1.19.0
  image = "sissbruecker/linkding@sha256:e701d36539de60adbb639c3dff5d3e06b7e4803eaa93b8e7252c2649dec9fe33";
in {
  nomad.jobs.linkding = {
    priority = 60;

    taskGroups.linkding = {
      architecture = "arm64";

      services = [
        {
          inherit name;
          port = 9090;
          connect.enable = true;

          checks = [
            {
              http.path = "/health";
              interval = 15;
              timeout = 3;
            }
          ];
        }
      ];

      tasks.linkding = {
        docker = {inherit image;};
        env = {
          LD_SUPERUSER_NAME = "mjm";
          LD_ENABLE_AUTH_PROXY = "True";
          LD_AUTH_PROXY_USERNAME_HEADER = "HTTP_REMOTE_USER";
          LD_AUTH_PROXY_LOGOUT_URL = "https://auth.midna.dev/logout";
          LD_CSRF_TRUSTED_ORIGINS = "https://links.midna.dev";
          LD_DB_ENGINE = "postgres";
          LD_DB_DATABASE = "linkding";
          LD_DB_HOST = "postgresql.service.consul";
        };
        cpu = 200;
        memory = 300;
        loggingTag = name;
        vault.policies = [name];

        templates."secrets/db.env" = {
          text = ''
            {{ with secret "database/creds/linkding" }}
            LD_DB_USER={{ .Data.username }}
            LD_DB_PASSWORD={{ .Data.password }}
            {{ end }}
          '';
          changeMode = "restart";
          envVars = true;
        };
      };
    };
  };

  vault.databases.roles.linkding = {
    ttl = "long";
  };

  vault.policies.linkding.text = ''
    path "database/creds/linkding" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.links = {
    upstream.service = {
      inherit name;
      connectPort = 9090;
    };
    external = true;
  };
}
