{
  inputs,
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
  # TODO remove once a module for attic lands in nixpkgs
  imports = [ "${inputs.attic}/nixos/atticd.nix" ];

  options.mjm.atticd = {
    enable = mkEnableOption "atticd";
  };

  config = mkIf cfg.enable {
    mjm.postgresql.enable = true;
    deployment.tags = [ "svc-atticd" ];

    services.atticd = {
      enable = true;
      package = pkgs.attic-server;
      # TODO remove once a module for attic lands in nixpkgs
      useFlakeCompatOverlay = false;
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
      credentialsFile = config.vault-secrets.templates.attic-env.path;
    };

    vault-secrets.wantedBy = [ "atticd.service" ];
    vault-secrets.templates.attic-env.text = ''
      {{ with secret "kv/prod/services/atticd" }}
      ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64={{ .Data.data.token_secret }}
      AWS_ACCESS_KEY_ID={{ .Data.data.garage_key_id }}
      AWS_SECRET_ACCESS_KEY={{ .Data.data.garage_secret_key }}
      {{ end }}
    '';

    services.postgresql = {
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
  };
}
