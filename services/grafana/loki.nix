{
  pkgs,
  config,
  lib,
  ...
}:
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

        server.http_listen_address = "127.0.0.1";
        # this listening on the host's actual IP seems to be important to loki functioning
        # server.grpc_listen_address = "127.0.0.1";
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
          };
          tsdb_shipper = {
            active_index_directory = "${dataDir}/tsdb-index";
            cache_location = "${dataDir}/tsdb-cache";
          };
        };

        schema_config.configs = [
          {
            from = "2024-04-15";
            store = "tsdb";
            object_store = "s3";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        compactor = {
          working_directory = "${dataDir}/compactor";
          retention_enabled = true;
          delete_request_store = "s3";
        };

        limits_config = {
          retention_period = "672h";
          allow_structured_metadata = true;
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

    mjm.spire.tunnels.loki = {
      mode = "server";
      port = 3103;
      target = "localhost:3100";
      allowedServices = [ "promtail" ];
      allowMetrics = true;
    };

    services.consul.services.loki = {
      port = 3103;
      metrics.enable = true;
      metrics.tls = true;

      checks.up = {
        http.path = "/ready";
        http.port = 3100;
      };
    };

    deployment.tests = {
      inherit (pkgs.nixosTests) loki;
    };
  };
}
