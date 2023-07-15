{
  services.minio = {
    enable = true;
  };

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
