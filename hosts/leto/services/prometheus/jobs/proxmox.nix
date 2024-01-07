{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "proxmox";
      metrics_path = "/pve";
      params = {
        target = ["proxmox.service.consul"];
      };
      consul_sd_configs = [
        {
          server = "127.0.0.1:8500";
          services = ["pve-exporter"];
        }
      ];
    }
  ];
}
