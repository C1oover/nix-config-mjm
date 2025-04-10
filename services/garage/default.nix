{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    ;
in
{
  options.mjm.garage = {
    enable = mkEnableOption "garage";
  };

  config = mkIf config.mjm.garage.enable {
    mjm.services.garage = {
      vault = {
        enable = true;
        useSpiffeIdentity = true;
      };
    };

    services.garage = {
      enable = true;
      package = pkgs.garage_1_x;
      settings = {
        db_engine = "lmdb";
        replication_factor = 3;
        rpc_bind_addr = "[::]:3901";

        s3_api = {
          s3_region = "home";
          api_bind_addr = "[::]:3902";
        };

        consul_discovery = {
          consul_http_addr = "http://127.0.0.1:8500";
          api = "agent";
          service_name = "garage";
        };

        admin.api_bind_addr = "[::]:3903";
      };
      # These aren't used in the `garage` wrapper script :-/
      extraEnvironment = {
        GARAGE_RPC_SECRET_FILE = "%d/garage_rpc_secret";
        GARAGE_ADMIN_TOKEN_FILE = "%d/garage_admin_token";
        # they're not actually world-readable, i promise, it just
        # doesn't like the 440 permissions systemd gives them
        GARAGE_ALLOW_WORLD_READABLE_SECRETS = "true";
      };
    };

    systemd.services.garage.serviceConfig = {
      StateDirectory = mkForce "garage/meta garage/data";
      LoadCredential = map (k: "garage_${k}:/run/garage-creds.sock") [
        "rpc_secret"
        "admin_token"
      ];
    };

    mjm.state.directories = [ "/var/lib/private/garage/meta" ];

    ingress.virtualHosts.garage = {
      upstream.service = {
        name = "garage";
        tag = "s3";
      };
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs.callPackages ./scripts.nix { garage = config.services.garage.package; }) g;
    };

    networking.firewall.allowedTCPPorts = [
      3901
      3902
      3903
    ];

    services.consul.services.garage = {
      port = 3902;

      metrics.enable = true;
      metrics.port = 3903;

      serviceConfig.tags = [ "s3" ];

      checks.up = {
        http.url = "http://localhost:3903/health";
      };
    };

    deployment.consulChecks = [ "garage" ];
    deployment.tests = {
      inherit (pkgs.nixosTests.garage)
        basic1_x
        with-3node-replication1_x
        ;
    };
  };
}
