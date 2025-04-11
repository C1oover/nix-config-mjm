{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.grafana;
in
{
  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        tempo = prev.tempo.overrideAttrs {
          patches = [ ./tempo.diff ];
        };
      })
    ];
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
          grpc.endpoint = "127.0.0.1:24317";
          # used by launchpad in dev
          # TODO fix to be able to create a tunnel for it on the dev machine
          http.endpoint = "0.0.0.0:14318";
        };

        compactor.compaction.block_retention = "48h";

        storage.trace = {
          backend = "s3";
          s3 = {
            endpoint = "localhost:3905";
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

    systemd.services.tempo.environment = {
      SPIFFE_ENDPOINT_SOCKET = "unix:${config.mjm.spire.agent.socketPath}";
      AWS_SHARED_CREDENTIALS_FILE = pkgs.writeText "spiffe-garage-aws-credentials" ''
        [default]
        credential_process = ${pkgs.spiffe-garage}/bin/spiffe-garage-helper
      '';
    };

    mjm.spire.tunnels = {
      tempo-grpc = {
        mode = "server";
        port = 14317;
        target = "localhost:24317";
      };
      tempo-s3 = {
        mode = "client";
        port = 3905;
        target = "s3.garage.service.consul:3902";
        service = "garage";
      };
    };

    services.consul.services.tempo = {
      port = 3200;

      checks.up = {
        http.path = "/ready";
      };
    };

    networking.firewall.allowedTCPPorts = [ 14318 ];
  };
}
