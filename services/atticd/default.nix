{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.atticd;

  # on main, the attic module is updated to work with RS256 tokens instead of
  # HS256, but I'm using the version in nixpkgs which doesn't have that, so I
  # need to pin to an older module. it's kind of wild to me that there still
  # isn't an attic module in nixpkgs.
  attic = builtins.fetchTarball {
    url = "https://github.com/zhaofengli/attic/archive/61ebdef2e263c091f24807b07701be5cb8068dea.tar.gz";
    sha256 = "1b2k283wl6x1mnz1rs6arjr4gqx78fzxkchmvyragvf5h2732662";
  };
in
{
  # TODO remove once a module for attic lands in nixpkgs
  imports = [ "${attic}/nixos/atticd.nix" ];

  options.mjm.atticd = {
    enable = mkEnableOption "atticd";
  };

  config = mkIf cfg.enable {
    mjm.services.atticd = {
      postgresql.enable = true;
    };

    ingress.virtualHosts.attic = {
      upstream.service.name = "attic";
      enableAuthProxy = false;
    };

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
          endpoint = "https://garage.midna.dev";
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

    vault.services.atticd = { };
    vault-secrets.wantedBy = [ "atticd.service" ];
    vault-secrets.templates.attic-env.text = ''
      {{ with secret "kv/prod/services/atticd" }}
      ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64={{ .Data.data.token_secret }}
      AWS_ACCESS_KEY_ID={{ .Data.data.garage_key_id }}
      AWS_SECRET_ACCESS_KEY={{ .Data.data.garage_secret_key }}
      {{ end }}
    '';

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
