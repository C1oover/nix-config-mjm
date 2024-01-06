{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "consul-connect-envoy";
      scrape_interval = "300s";
      consul_sd_configs = [
        {server = "127.0.0.1:8500";}
      ];
      relabel_configs = [
        {
          source_labels = ["__meta_consul_service"];
          action = "drop";
          regex = "(.+)-sidecar-proxy";
        }
        {
          source_labels = ["__meta_consul_service_metadata_envoy_metrics_port"];
          action = "keep";
          regex = "(.+)";
        }
        {
          source_labels = ["__meta_consul_service"];
          target_label = "service_name";
          regex = "(.+)";
        }
        {
          source_labels = ["__meta_consul_node"];
          target_label = "node_name";
          regex = "(.+)";
        }
        {
          source_labels = ["__address__" "__meta_consul_service_metadata_envoy_metrics_port"];
          regex = "([^:]+)(?::\\d+)?;(\\d+)";
          replacement = "$1:$2";
          target_label = "__address__";
        }
      ];
    }
  ];
}
