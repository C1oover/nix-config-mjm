{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "pushgateway";
      consul_sd_configs = [
        {
          services = ["pushgateway"];
          server = "127.0.0.1:8500";
        }
      ];
      honor_labels = true;
    }
  ];
}
