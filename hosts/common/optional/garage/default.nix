{ pkgs, config, ... }:
{
  services.garage = {
    enable = true;
    package = pkgs.garage_0_9;
    settings = {
      db_engine = "lmdb";
      replication_mode = "3";
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
    environmentFile = config.vault-secrets.templates.garage-env.path;
  };

  systemd.services.garage.after = [ "render-vault-secrets.service" ];

  vault-secrets.templates.garage-env.text = ''
    {{ with secret "kv/garage" }}
    GARAGE_RPC_SECRET={{ .Data.data.rpc_secret }}
    GARAGE_ADMIN_TOKEN={{ .Data.data.admin_token }}
    {{ end }}
  '';

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

    tags = [ "s3" ];

    meta = {
      metrics_path = "/metrics";
      metrics_port = "3903";
    };

    checks = [
      {
        name = "garage is ready";
        http = "http://localhost:3903/health";
        interval = "15s";
        timeout = "10s";
      }
    ];
  };
}
