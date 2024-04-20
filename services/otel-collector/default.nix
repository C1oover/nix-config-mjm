{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.otel-collector;
in
{
  options.mjm.otel-collector = {
    enable = mkEnableOption "OpenTelemetry collector";
  };

  config = mkIf cfg.enable {
    deployment.tags = [ "svc-otel-collector" ];

    services.opentelemetry-collector = {
      enable = true;
      settings = {
        receivers.otlp.protocols = {
          grpc.endpoint = "127.0.0.1:4317";
          http.endpoint = "127.0.0.1:4318";
        };

        processors = {
          batch = { };
          memory_limiter = {
            check_interval = "5s";
            limit_mib = 400;
            spike_limit_mib = 100;
          };
        };

        exporters = {
          "otlp/honeycomb" = {
            endpoint = "api.honeycomb.io:443";
            headers.x-honeycomb-team = "\${env:HONEYCOMB_API_KEY}";
          };
          "otlp/tempo" = {
            endpoint = "tempo.service.consul:14317";
            tls.insecure = true;
          };
        };

        extensions = {
          # health_check = { };
          # pprof = { };
          zpages = { };
          memory_ballast.size_mib = 165;
        };

        service = {
          extensions = [
            # "health_check"
            # "pprof"
            "zpages"
            "memory_ballast"
          ];
          pipelines.traces = {
            receivers = [ "otlp" ];
            processors = [
              "memory_limiter"
              "batch"
            ];
            exporters = [
              # "otlp/honeycomb"
              "otlp/tempo"
            ];
          };
          telemetry.metrics = {
            address = "0.0.0.0:4319";
          };
        };
      };
    };

    systemd.services.opentelemetry-collector.serviceConfig.EnvironmentFile =
      config.vault-secrets.templates.otel-collector-env.path;

    vault-secrets.wantedBy = [ "opentelemetry-collector.service" ];
    vault-secrets.templates.otel-collector-env.text = ''
      {{ with secret "kv/prod/services/otel-collector" }}
      HONEYCOMB_API_KEY={{ .Data.data.honeycomb_api_key }}
      {{ end }}
    '';
  };
}
