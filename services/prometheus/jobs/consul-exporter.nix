{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "consul-exporter";
      static_configs = [ { targets = [ "127.0.0.1:9107" ]; } ];
      metrics_path = "/metrics";
    }
  ];
}
