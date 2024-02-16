{ config, ... }:
{
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

      exporters.otlp = {
        endpoint = "api.honeycomb.io:443";
        headers.x-honeycomb-team = "\${env:HONEYCOMB_API_KEY}";
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
          exporters = [ "otlp" ];
        };
        telemetry.metrics = {
          address = "0.0.0.0:4319";
        };
      };
    };
  };

  systemd.services.opentelemetry-collector = {
    after = [ "render-vault-secrets.service" ];
    serviceConfig.EnvironmentFile = config.vault-secrets.templates.otel-collector-env.path;
  };

  vault-secrets.templates.otel-collector-env.text = ''
    {{ with secret "kv/honeycomb" }}
    HONEYCOMB_API_KEY={{ .Data.data.api_key }}
    {{ end }}
  '';
}
