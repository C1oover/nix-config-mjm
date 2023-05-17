{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "consul-services";
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
          source_labels = ["__meta_consul_service_metadata_metrics_path"];
          action = "keep";
          regex = "(.+)";
        }
        {
          source_labels = ["__meta_consul_service_metadata_metrics_path"];
          target_label = "__metrics_path__";
          regex = "(.+)";
        }
        {
          source_labels = ["__meta_consul_service"];
          target_label = "service_name";
          regex = "(.+)";
        }
        {
          source_labels = ["service_name"];
          target_label = "service_name";
          regex = "(.+)-metrics";
        }
        {
          source_labels = ["__meta_consul_node"];
          target_label = "node_name";
          regex = "(.+)";
        }
        {
          source_labels = ["__address__" "__meta_consul_service_metadata_metrics_port"];
          regex = "([^:]+)(?::\\d+)?;(\\d+)";
          replacement = "$1:$2";
          target_label = "__address__";
        }
      ];
    }
  ];
}
