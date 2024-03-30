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
          http_listen_port = 3200;
          grpc_listen_port = 3201;
        };

        distributor.receivers.otlp.protocols = {
          grpc.endpoint = "0.0.0.0:14317";
        };

        compactor.compaction.block_retention = "48h";

        storage.trace = {
          backend = "s3";
          s3 = {
            endpoint = "garage.service.consul:3902";
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

    services.consul.services.tempo = {
      port = 3200;

      checks = [
        {
          name = "tempo is ready";
          http = "http://localhost:3200/ready";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [
      3200
      3201
      14317
    ];
  };
}
