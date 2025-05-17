{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.tempo;
in
{
  options.mjm.tempo = {
    enable = mkEnableOption "Grafana Tempo";
  };

  config = mkIf cfg.enable {
    mjm.services.tempo = { };

    services.tempo = {
      enable = true;
      settings = {
        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = 3300;
          grpc_listen_address = "127.0.0.1";
          grpc_listen_port = 3201;
        };

        distributor.receivers.otlp.protocols = {
          # used by alloy, goes through the tunnel for mTLS
          grpc.endpoint = "127.0.0.1:16317";
          # used by launchpad in dev
          # TODO fix to be able to create a tunnel for it on the dev machine
          http.endpoint = "0.0.0.0:14318";
        };

        compactor.compaction.block_retention = "48h";

        storage.trace = {
          backend = "s3";
          s3 = {
            endpoint = "localhost:3902";
            bucket = "tempo-traces";
            region = "home";
            insecure = true;
            forcepathstyle = true;
          };
          wal.path = "/var/lib/tempo/wal";
          local.path = "/var/lib/tempo/blocks";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 14318 ];

    mjm.garage.clients.tempo.services = [ "tempo" ];

    mjm.spire.tunnels = {
      tempo = {
        mode = "server";
        listen.port = 3200;
        target.port = 3300;
        allowedServices = [ "grafana" ];
        allowConsul = true;
      };
      tempo-grpc = {
        mode = "server";
        listen.port = 14317;
        target.port = 16317;
        allowedServices = [ "alloy" ];
      };
    };

    services.consul.services.tempo = {
      port = 3200;

      checks.up = {
        http.path = "/ready";
        http.port = 3300;
      };
    };
  };
}
