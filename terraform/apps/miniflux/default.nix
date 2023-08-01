let
  name = "miniflux";
  # miniflux 2.0.46
  image = "ghcr.io/miniflux/miniflux@sha256:0625952a7e45ff8824936d71eeaca57205c12b758d5b47e27fe11df98bebfcff";
in {
  nomad.jobs.miniflux = {
    priority = 60;

    taskGroups.miniflux = {
      count = 2;

      services = [
        {
          inherit name;
          port = 8080;
          metrics.enable = true;
          connect.enable = true;
          connect.upstreams.linkding = 9090;

          checks = [
            {
              http.path = "/healthcheck";
              interval = 15;
              timeout = 3;
            }
          ];
        }
      ];

      tasks.miniflux = {
        docker = {inherit image;};
        env = {
          BASE_URL = "https://feeds.midna.dev/";
          METRICS_COLLECTOR = "1";
          RUN_MIGRATIONS = "1";
          AUTH_PROXY_HEADER = "Remote-User";
          AUTH_PROXY_USER_CREATION = "1";
        };
        cpu = 200;
        memory = 300;
        loggingTag = name;
        vault.policies = [name];

        templates."secrets/db.env" = {
          text = ''
            {{ with secret "database/creds/miniflux" }}
            DATABASE_URL=postgres://{{ .Data.username }}:{{ .Data.password }}@postgresql.service.consul/miniflux?sslmode=disable
            {{ end }}
          '';
          changeMode = "restart";
          envVars = true;
        };
      };
    };
  };

  vault.databases.roles.miniflux = {
    ttl = "short";
  };

  vault.policies.miniflux.text = ''
    # Allow miniflux to read credentials for accessing its database
    path "database/creds/miniflux" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.feeds = {
    upstream.service = {
      inherit name;
      connectPort = 8080;
    };

    external = true;
  };
}
