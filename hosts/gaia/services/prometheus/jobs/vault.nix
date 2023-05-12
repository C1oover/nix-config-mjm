{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "vault";
      consul_sd_configs = [
        {
          services = [ "vault" ];
          server = "127.0.0.1:8500";
        }
      ];
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
