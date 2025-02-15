{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.atticd;
in
{
  options.mjm.atticd = {
    enable = mkEnableOption "atticd";
  };

  config = mkIf cfg.enable {
    mjm.services.atticd = {
      vault.enable = true;
      postgresql.enable = true;
    };

    ingress.virtualHosts.attic = {
      upstream.service.name = "attic";
      enableAuthProxy = false;
    };

    services.atticd = {
      enable = true;
      settings = {
        listen = "[::]:8100";
        database.url = "postgresql:///atticd?host=/run/postgresql";
        storage = {
          type = "s3";
          region = "home";
          bucket = "attic-caches";
          endpoint = "https://garage.midna.dev";
        };
        compression.type = "zstd";
        garbage-collection.default-retention-period = "3 months";
      };
      environmentFile = config.vault-secrets.templates.attic-env.path;
    };

    vault-secrets.wantedBy = [ "atticd.service" ];
    vault-secrets.templates.attic-env.text = ''
      {{ with secret "kv/prod/services/atticd" }}
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64={{ .Data.data.token_rs256_secret }}
      AWS_ACCESS_KEY_ID={{ .Data.data.garage_key_id }}
      AWS_SECRET_ACCESS_KEY={{ .Data.data.garage_secret_key }}
      {{ end }}
    '';

    networking.firewall.allowedTCPPorts = [ 8100 ];

    services.consul.services.attic = {
      port = 8100;

      checks.up = {
        http.path = "/";
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) atticd;
    };
  };
}
