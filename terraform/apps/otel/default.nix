let
  name = "otel-collector";
  image = "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib@sha256:a69b30adceef622a2711101499610823f5735ac8a95439418cddacdceb428b1a";
in {
  nomad.jobs.otel-collector = {
    priority = 70;
    type = "system";

    taskGroups.otel-collector = {
      ports = {
        healthcheck.to = 13133;
        metrics.to = 8888;
        jaeger_thrift.static = 14268;
        zipkin.static = 9411;
        otlp_grpc.static = 4317;
        otlp_http.static = 4318;
      };

      services = [
        {
          inherit name;
          port = "otlp_grpc";
          tags = ["grpc"];
          metrics = {
            enable = true;
            port = "metrics";
          };

          checks = [
            {
              http.path = "/";
              http.port = "healthcheck";
              interval = 15;
              timeout = 3;
              successBeforePassing = 3;
            }
          ];
        }
      ];

      tasks.otel-collector = {
        docker = {
          inherit image;
          args = ["--config" "$\${NOMAD_SECRETS_DIR}/config.yaml"];
        };
        ports = [
          "healthcheck"
          "metrics"
          "jaeger_thrift"
          "zipkin"
          "otlp_grpc"
          "otlp_http"
        ];
        cpu = 500;
        memory = 500;
        loggingTag = name;
        vault.policies = [name];
        vault.changeMode = "noop";

        templates."secrets/config.yaml" = {
          source = ./otel-collector-config.yaml;
          changeMode = "restart";
        };
      };
    };
  };

  vault.policies.otel-collector.text = ''
    # Allow the OpenTelemetry collector to read the Honeycomb API key
    path "kv/data/honeycomb" {
      capabilities = ["read"]
    }
  '';
}
