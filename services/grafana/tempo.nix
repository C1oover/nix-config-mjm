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
        namespace = "tempo";
        port = 3200;
        target = "localhost:3200";
        allowedServices = [
          "grafana"
          "consul-agent"
        ];
      };
      tempo-grpc = {
        mode = "server";
        namespace = "tempo";
        port = 14317;
        target = "localhost:14317";
        allowedServices = [ "otel-collector" ];
      };
      tempo-s3 = {
        mode = "client";
        namespace = "tempo";
        port = 3902;
        target = "s3.garage.service.consul:3902";
        service = "garage";
      };
      tempo-s3-creds = {
        mode = "client";
        namespace = "tempo";
        listen = "169.254.170.2:80";
        target = "spiffe-garage.service.consul:3899";
        service = "spiffe-garage";
      };
      consul-tempo = {
        mode = "client";
        socket = "/run/consul-checks/tempo.sock";
        target = "localhost:3200";
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
