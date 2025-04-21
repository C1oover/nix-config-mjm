{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.grafana;
in
{
  config = mkIf cfg.enable {
    services.tempo = {
      enable = true;
      settings = {
        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = 3200;
          grpc_listen_address = "127.0.0.1";
          grpc_listen_port = 3201;
        };

        distributor.receivers.otlp.protocols = {
          # used by otel-collector, goes through the tunnel for mTLS
          grpc.endpoint = "127.0.0.1:14317";
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

    systemd.services.tempo = {
      bindsTo = [ "netns-bridge@tempo.service" ];
      after = [ "netns-bridge@tempo.service" ];
      serviceConfig.NetworkNamespacePath = "/run/netns/tempo";
      environment.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI = "/creds";
    };

    mjm.spire.tunnels = {
      tempo = {
        mode = "server";
        listen.port = 3200;
        target.port = 3200;
        target.namespace = "tempo";
        allowedServices = [ "grafana" ];
        allowConsul = true;
      };
      tempo-grpc = {
        mode = "server";
        listen.port = 14317;
        target.port = 14317;
        target.namespace = "tempo";
        allowedServices = [ "otel-collector" ];
      };
      tempo-s3 = {
        mode = "client";
        listen.port = 3902;
        listen.namespace = "tempo";
        target.service = "s3.garage";
        target.port = 3902;
        service = "garage";
      };
      tempo-s3-creds = {
        mode = "client";
        listen.address = "169.254.170.2:80";
        listen.namespace = "tempo";
        target.service = "spiffe-garage";
        target.port = 3899;
      };
      consul-tempo = {
        mode = "client";
        listen.socket = "/run/consul-checks/tempo.sock";
        target.port = 3200;
        service = "tempo";
      };
    };

    services.consul.services.tempo = {
      port = 3200;

      checks.up = {
        http.path = "/ready";
        http.socket = "/run/consul-checks/tempo.sock";
      };
    };
  };
}
