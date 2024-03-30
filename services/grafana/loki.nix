{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (config.services.loki) dataDir;

  cfg = config.mjm.grafana;
in
{
  config = mkIf cfg.enable {
    services.loki = {
      enable = true;
      extraFlags = [ "-config.expand-env=true" ];
      configuration = {
        auth_enabled = false;

        server.grpc_listen_port = 3102;

        querier.max_concurrent = 16;

        query_scheduler.max_outstanding_requests_per_tenant = 32768;

        ruler = {
          storage = {
            type = "local";
            local.directory = "/tmp/rules/fake";
          };
          rule_path = "${dataDir}/rules";
          alertmanager_url = "http://127.0.0.1:9093";
          ring.kvstore.store = "inmemory";
          enable_api = true;
        };

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
            final_sleep = "5m";
          };
          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
          max_transfer_retries = 0;
          wal.enabled = false;
        };

        storage_config = {
          aws = {
            s3 = "http://\${AWS_ACCESS_KEY_ID}:\${AWS_SECRET_ACCESS_KEY}@garage.service.consul:3902";
            region = "home";
            bucketnames = "loki-logs";
            insecure = true;
            s3forcepathstyle = true;
          };
          boltdb_shipper = {
            active_index_directory = "${dataDir}/boltdb-shipper-active";
            cache_location = "${dataDir}/boltdb-shipper-cache";
            cache_ttl = "24h";
            shared_store = "s3";
          };
          tsdb_shipper = {
            active_index_directory = "${dataDir}/tsdb-index";
            cache_location = "${dataDir}/tsdb-cache";
            shared_store = "s3";
          };
        };

        chunk_store_config.max_look_back_period = "0s";

        schema_config.configs = [
          {
            from = "2020-07-01";
            store = "boltdb-shipper";
            object_store = "aws";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
          {
            from = "2024-02-12";
            store = "tsdb";
            object_store = "aws";
            schema = "v12";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        compactor = {
          working_directory = "${dataDir}/compactor";
          shared_store = "s3";
        };

        limits_config.enforce_metric_name = false;

        table_manager = {
          retention_deletes_enabled = true;
          retention_period = "672h";
        };
      };
    };

    systemd.services.loki.serviceConfig.EnvironmentFile = config.vault-secrets.templates.loki-env.path;

    vault-secrets.wantedBy = [ "loki.service" ];
    vault-secrets.templates.loki-env.text = ''
      {{ with secret "kv/prod/services/grafana" }}
      AWS_ACCESS_KEY_ID={{ .Data.data.loki_garage_key_id }}
      AWS_SECRET_ACCESS_KEY={{ .Data.data.loki_garage_secret_key }}
      {{ end }}
    '';

    networking.firewall.allowedTCPPorts = [ 3100 ];

    services.consul.services.loki = {
      port = 3100;

      meta.metrics_path = "/metrics";

      checks = [
        {
          name = "loki is ready";
          http = "http://localhost:3100/ready";
          interval = "15s";
          timeout = "5s";
        }
      ];
    };
  };
}
