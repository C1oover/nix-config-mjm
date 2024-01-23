{ lib, inputs, ... }:
{
  imports = [ inputs.attic.nixosModules.atticd ];

  services.atticd = {
    enable = true;
    settings = {
      listen = "[::]:8100";
      database = lib.mkForce { };
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
    credentialsFile = "/run/secrets/attic/attic.env";
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

  systemd.tmpfiles.settings."10-secrets"."/run/secrets/attic".d = {
    mode = "0700";
    user = "root";
    group = "root";
  };

  services.vault-agent.instances.main.templates = [
    {
      contents = ''
        {{ with secret "kv/attic" }}
        ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64={{ .Data.data.token_secret }}
        AWS_ACCESS_KEY_ID={{ .Data.data.garage_key_id }}
        AWS_SECRET_ACCESS_KEY={{ .Data.data.garage_secret_key }}
        {{ end }}
        {{ with secret "database/creds/attic" }}
        ATTIC_SERVER_DATABASE_URL=postgres://{{ .Data.username }}:{{ .Data.password }}@postgresql.service.consul/attic
        {{ end }}
      '';
      destination = "/run/secrets/attic/attic.env";
      command = "systemctl restart atticd.service";
    }
  ];
}
