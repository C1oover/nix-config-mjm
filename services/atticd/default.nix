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
      vault = {
        enable = true;
        useSpiffeIdentity = true;
      };
      postgresql.enable = true;
    };

    ingress.virtualHosts.attic = {
      upstream = {
        service.name = "atticd";
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
      environmentFile = "/run/atticd-env/env";
    };

    systemd.services.atticd-env = {
      wantedBy = [ "atticd.service" ];
      before = [ "atticd.service" ];
      path = [ pkgs.systemd ];
      startLimitIntervalSec = 0;
      script = ''
        echo "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=$(systemd-creds cat atticd_token_rs256_secret)" > /run/atticd-env/env
      '';
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = 5;
        RemainAfterExit = true;
        DynamicUser = true;
        PrivateNetwork = true;
        PrivateTmp = true;
        RuntimeDirectory = "atticd-env";
        RuntimeDirectoryMode = "0700";
        LoadCredential = [
          "atticd_token_rs256_secret:/run/atticd-creds.sock"
        ];
      };
    };

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
        listen.socket = "/run/consul-checks/atticd.sock";
        target.port = 8100;
        service = "atticd";
      };
    };

    services.consul.services.atticd = {
      port = 8100;

      checks.up = {
        http.path = "/";
        http.socket = "/run/consul-checks/atticd.sock";
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) atticd;
    };
  };
}
