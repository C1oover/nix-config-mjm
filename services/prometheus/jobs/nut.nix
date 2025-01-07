{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nut";
      metrics_path = "/ups_metrics";
      static_configs = [
        {
          targets = [
            "or500"
            "smart500"
          ];
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_ups";
        }
        {
          source_labels = [ "__param_ups" ];
          target_label = "ups";
        }
        {
          target_label = "__address__";
          replacement = "nut-exporter.service.consul:9199";
        }
      ];
    }
  ];
}
