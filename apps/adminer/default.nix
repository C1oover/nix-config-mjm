{ config, ... }:
let
  name = "adminer";
  # adminer 4.8.1
  image = "adminer@sha256:ea38d6384f8f6f0dc29705d6497ca7d77af3e664288d655e574f433d592030df";

  databases = config.vault.databases.roles;
in
{
  nomad.jobs.adminer = {
    priority = 50;

    taskGroups.adminer = {
      # It's important that this only has 1 task, because it stores session data in files, so if there's multiple,
      # then we load-balance between them and don't have consistent session data. We could probably also just IP hash
      # in the ingress, but there's not much reason to need redundancy for something like this.
      count = 1;
      architecture = "arm64";

      services = [
        {
          inherit name;
          port = 8080;
          connect.enable = true;
        }
      ];

      tasks.adminer = {
        docker = {
          inherit image;
          volumes = [ "secrets/plugins:/var/www/html/plugins-enabled" ];
        };
        cpu = 100;
        memory = 100;
        loggingTag = name;
        vault.policies = [ name ];

        templates."secrets/plugins/login-static.php".text = import ./login-static.nix {
          inherit databases;
        };
      };
    };
  };

  vault.policies.adminer.text = ''
    # Allow adminer to read credentials for any database
    path "database/creds/*" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.sql = {
    upstream.service = {
      inherit name;
      connectPort = 10000;
    };
  };
}
