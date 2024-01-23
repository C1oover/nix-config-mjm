let
  name = "atuin";
  image = "ghcr.io/atuinsh/atuin@sha256:73fe07e5f36e96dfb6badbe8abe75b9004c06ed17490cc3e3b2328daad223db3";
in
{
  nomad.jobs.atuin = {
    priority = 60;

    taskGroups.atuin = {
      architecture = "amd64";

      services = [
        {
          inherit name;
          port = 8888;
          connect.enable = true;
        }
      ];

      tasks.atuin = {
        docker = {
          inherit image;
          args = [
            "server"
            "start"
          ];
          volumes = [ "local:/config" ];
        };
        env = {
          ATUIN_HOST = "0.0.0.0";
          ATUIN_OPEN_REGISTRATION = "true";
        };
        cpu = 200;
        memory = 300;
        loggingTag = name;
        vault.policies = [ name ];

        templates."secrets/db.env" = {
          text = ''
            {{ with secret "database/creds/atuin" }}
            ATUIN_DB_URI=postgres://{{ .Data.username }}:{{ .Data.password }}@postgresql.service.consul/atuin
            {{ end }}
          '';
          changeMode = "restart";
          envVars = true;
        };
      };
    };
  };

  vault.databases.roles.atuin = {
    ttl = "short";
  };

  vault.policies.atuin.text = ''
    path "database/creds/atuin" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.atuin = {
    upstream.service = {
      inherit name;
      connectPort = 8888;
    };
    enableAuthProxy = false;
  };
}
