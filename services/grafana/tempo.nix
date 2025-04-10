{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.grafana;
in
{
  config = mkIf cfg.enable {
    services.tempo = {
      enable = true;
      extraFlags = [ "-config.expand-env=true" ];
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
            access_key = "\${AWS_ACCESS_KEY_ID}";
            secret_key = "\${AWS_SECRET_ACCESS_KEY}";
            insecure = true;
            forcepathstyle = true;
          };
          wal.path = "/var/lib/tempo/wal";
          local.path = "/var/lib/tempo/blocks";
        };
      };
    };

    systemd.services.tempo.serviceConfig.EnvironmentFile =
      config.vault-secrets.templates.tempo-env.path;

    vault-secrets.wantedBy = [ "tempo.service" ];
    vault-secrets.templates.tempo-env.text = ''
      {{ with secret "kv/prod/services/grafana" }}
      AWS_ACCESS_KEY_ID={{ .Data.data.tempo_garage_key_id }}
      AWS_SECRET_ACCESS_KEY={{ .Data.data.tempo_garage_secret_key }}
      {{ end }}
    '';

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
