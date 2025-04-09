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
    mjm.services.otel-collector = { };

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
          "otlp/tempo" = {
            endpoint = "tempo.service.consul:14317";
            tls.insecure = true;
          };
        };

        extensions = {
          # health_check = { };
          # pprof = { };
          zpages = { };
        };

        service = {
          extensions = [
            # "health_check"
            # "pprof"
            "zpages"
          ];
          pipelines.traces = {
            receivers = [ "otlp" ];
            processors = [
              "memory_limiter"
              "batch"
            ];
            exporters = [
              "otlp/tempo"
            ];
          };
          telemetry.metrics = {
            address = "0.0.0.0:4319";
          };
        };
      };
    };
  };
}
