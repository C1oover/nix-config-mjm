{config, ...}: {
  services.minio = {
    enable = true;
    rootCredentialsFile = config.age.secrets."minio-root-credentials".path;
  };

  systemd.services.minio.environment = {
    MINIO_PROMETHEUS_AUTH_TYPE = "public";
    MINIO_PROMETHEUS_URL = "http://prometheus.service.consul:9090";
    MINIO_PROMETHEUS_JOB_ID = "consul-services";
    MINIO_BROWSER_REDIRECT_URL = "https://minio-console.home.mattmoriarity.com";
  };

  age.secrets."minio-root-credentials".file = ../../../secrets/minio-root-credentials.age;

  networking.firewall.allowedTCPPorts = [
    9000
    9001
  ];

  services.consul.services = {
    minio = {
      port = 9000;
      meta.metrics_path = "/minio/v2/metrics/cluster";

      checks = [
        {
          name = "minio is ready";
          http = "http://localhost:9000/minio/health/cluster";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };

    minio-console = {
      port = 9001;

      checks = [
        {
          name = "minio-console is ready";
          http = "http://localhost:9001/";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };
  };
}
