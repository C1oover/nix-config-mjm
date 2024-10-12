{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "blackbox-dns-public";
      metrics_path = "/probe";
      params.module = [ "dns_public" ];
      static_configs = [
        {
          targets = [
            "8.8.4.4"
            "8.8.8.8"
            "1.0.0.1"
            "1.1.1.1"
            "10.0.2.34"
            "10.0.2.37"
          ];
          labels = {
            probe_type = "dns";
            probe_scope = "public";
          };
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "127.0.0.1:9115";
        }
      ];
    }
  ];
}
