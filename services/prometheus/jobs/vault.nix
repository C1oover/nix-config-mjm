{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "vault";
      consul_sd_configs = [
        {
          services = [ "vault" ];
          server = "localhost:8500";
        }
      ];
      scheme = "https";
      tls_config = {
        ca_file = "/run/certs/prometheus/bundle.pem";
        cert_file = "/run/certs/prometheus/cert.pem";
        key_file = "/run/certs/prometheus/key.pem";
        server_name = "vault.service.consul";
      };
      metrics_path = "/v1/sys/metrics";
      params.format = [ "prometheus" ];
      relabel_configs = [
        {
          source_labels = [ "__meta_consul_node" ];
          target_label = "node_name";
        }
      ];
    }
  ];
}
