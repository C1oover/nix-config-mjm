{ inputs, config, ... }:
{
  imports = [ inputs.attic.nixosModules.atticd ];

  services.atticd = {
    enable = true;
    settings = {
      listen = "[::]:8100";
      database.url = "postgresql:///atticd?host=/run/postgresql";
      storage = {
        type = "s3";
        region = "home";
        bucket = "attic-caches";
        endpoint = "http://garage.service.consul:3902";
      };
      chunking = {
        nar-size-threshold = 65536;
        min-size = 16384;
        avg-size = 65536;
        max-size = 262144;
      };
      compression.type = "zstd";
      garbage-collection.default-retention-period = "3 months";
    };
    credentialsFile = config.age.secrets."attic.env".path;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "atticd" ];
    ensureUsers = [
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 8100 ];

  services.consul.services.attic = {
    port = 8100;

    checks = [
      {
        name = "attic is ready";
        http = "http://localhost:8100/";
        interval = "15s";
        timeout = "10s";
      }
    ];
  };

  age.secrets."attic.env".file = ../../../secrets/attic-env.age;
}
