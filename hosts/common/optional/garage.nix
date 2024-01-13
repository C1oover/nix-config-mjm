{
  pkgs,
  lib,
  config,
  ...
}: {
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
    environmentFile = config.age.secrets."garage.env".path;
  };

  # Add a `g` command to the path that runs garage with the RPC secret
  # so it's convenient to manage the cluster.
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "g";
      runtimeInputs = [pkgs.systemd];
      text = ''
        systemd-run \
          --service-type=oneshot \
          -p EnvironmentFile=/run/agenix/garage.env \
          --wait \
          -qt \
          ${lib.getExe config.services.garage.package} \
          "$@"
      '';
    })
  ];

  networking.firewall.allowedTCPPorts = [3901 3902 3903];

  age.secrets."garage.env".file = ../../../secrets/garage-env.age;
}
