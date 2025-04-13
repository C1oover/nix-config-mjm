{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "consul-agent";
      consul_sd_configs = [
        {
          services = [ "consul" ];
          server = "consul.service.consul:8500";
        }
      ];
      metrics_path = "/v1/agent/metrics";
      params.format = [ "prometheus" ];
      relabel_configs = [
        {
          source_labels = [ "__meta_consul_tagged_address_lan_ipv6" ];
          target_label = "__address__";
          replacement = "[$1]:8500";
        }
        {
          source_labels = [ "__meta_consul_node" ];
          target_label = "node_name";
        }
      ];
    }
  ];
}
