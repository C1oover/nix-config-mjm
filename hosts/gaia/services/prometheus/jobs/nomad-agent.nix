{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nomad-agent";
      consul_sd_configs = [
        {
          services = ["nomad" "nomad-client"];
          tags = ["http"];
          server = "127.0.0.1:8500";
        }
      ];
      metrics_path = "/v1/metrics";
      params.format = ["prometheus"];
      relabel_configs = [
        {
          source_labels = ["__meta_consul_node"];
          target_label = "node_name";
        }
      ];
    }
  ];
}
