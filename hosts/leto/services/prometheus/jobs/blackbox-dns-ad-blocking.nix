{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "blackbox-dns-ad-blocking";
      metrics_path = "/probe";
      params.module = [ "dns_ad_blocking" ];
      static_configs = [
        {
          targets = [
            "10.0.2.47"
            "10.0.2.48"
          ];
          labels = {
            probe_type = "dns";
            probe_scope = "ad-blocking";
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
