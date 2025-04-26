{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "consul-agent";
      consul_sd_configs = [
        {
          services = [ "consul" ];
          server = "localhost:8500";
        }
      ];
      tls_config = {
        ca_file = "/run/certs/prometheus/bundle.pem";
        cert_file = "/run/certs/prometheus/cert.pem";
        key_file = "/run/certs/prometheus/key.pem";
        server_name = "server.dc1.consul";
      };
      metrics_path = "/v1/agent/metrics";
      params.format = [ "prometheus" ];
      scheme = "https";
      relabel_configs = [
        {
          source_labels = [ "__meta_consul_tagged_address_lan_ipv6" ];
          target_label = "__address__";
          replacement = "[$1]:8501";
        }
        {
          source_labels = [ "__meta_consul_node" ];
          target_label = "node_name";
        }
      ];
    }
  ];
}
