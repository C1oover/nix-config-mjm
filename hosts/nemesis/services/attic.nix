{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.attic.nixosModules.atticd
  ];

  services.atticd = {
    enable = true;
    settings = {
      listen = "0.0.0.0:8100";
      storage = {
        type = "s3";
        region = "us-east-1";
        bucket = "attic-caches";
        endpoint = "http://minio.service.consul:9000";
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

  networking.firewall.allowedTCPPorts = [8100];

  systemd.tmpfiles.rules = ["d /run/secrets/attic 0700 root root - -"];

  services.vault-agent.instances.atticd.settings = let
    va = import ../../../lib/vault-agent.nix {inherit pkgs;};
  in
    va.mkConfig {
      roleId = "a8deaca3-2f11-35d9-6cd0-974cff179593";
      secretIdFile = config.age.secrets."attic-approle-secret-id".path;
      templates = [
        {
          contents = ''
            {{ with secret "kv/attic" }}
            ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64={{ .Data.data.token_secret }}
            AWS_ACCESS_KEY_ID=attic
            AWS_SECRET_ACCESS_KEY={{ .Data.data.minio_password }}
            {{ end }}
            {{ with secret "database/creds/attic" }}
            ATTIC_SERVER_DATABASE_URL=postgres://{{ .Data.username }}:{{ .Data.password }}@postgresql.service.consul/attic
            {{ end }}
          '';
          destination = "/run/secrets/attic/attic.env";
          command = "systemctl restart atticd.service";
        }
      ];
    };

  age.secrets."attic-approle-secret-id".file = ../../../secrets/attic-approle-secret-id.age;
}
