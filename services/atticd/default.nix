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
      upstream = {
        service.name = "attic";
        tls.enable = true;
      };

      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.atticd = {
      enable = true;
      settings = {
        listen = "[::1]:8100";
        database.url = "postgresql:///atticd?host=/run/postgresql";
        storage = {
          type = "s3";
          region = "home";
          bucket = "attic-caches";
          # when there's only a single chunk, then attic will redirect to a pre-signed URL for
          # that chunk, so the endpoint needs to be publicly reachable
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
      {{ end }}
    '';

    mjm.networkd.macvlan.enable = true;

    systemd.services.atticd = {
      bindsTo = [ "netns-bridge@attic.service" ];
      after = [ "netns-bridge@attic.service" ];
      serviceConfig.NetworkNamespacePath = "/run/netns/attic";
      environment.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI = "/creds";
    };

    mjm.spire.tunnels = {
      attic = {
        mode = "server";
        listen.port = 8100;
        target.port = 8100;
        target.namespace = "attic";
        allowIngress = true;
        allowConsul = true;
      };
      attic-s3-creds = {
        mode = "client";
        listen.address = "169.254.170.2:80";
        listen.namespace = "attic";
        target.service = "spiffe-garage";
        target.port = 3899;
        target.namespace = "attic";
      };
      consul-attic = {
        mode = "client";
        listen.socket = "/run/consul-checks/attic.sock";
        target.port = 8100;
        service = "attic";
      };
    };

    services.consul.services.attic = {
      port = 8100;

      checks.up = {
        http.path = "/";
        http.socket = "/run/consul-checks/attic.sock";
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) atticd;
    };
  };
}
