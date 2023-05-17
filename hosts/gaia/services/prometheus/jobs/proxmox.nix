{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "proxmox";
      metrics_path = "/pve";
      consul_sd_configs = [
        {
          server = "127.0.0.1:8500";
          services = ["proxmox"];
        }
      ];
      relabel_configs = [
        {
          source_labels = ["__address__"];
          regex = "(.+):\\d+";
          target_label = "__param_target";
        }
        {
          source_labels = ["__param_target"];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "pve-exporter.service.consul:9221";
        }
      ];
    }
  ];
}
