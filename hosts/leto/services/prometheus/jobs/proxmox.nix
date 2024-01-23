{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "proxmox";
      static_configs = [ { targets = [ "127.0.0.1:9221" ]; } ];
      metrics_path = "/pve";
      params = {
        target = [ "proxmox.service.consul" ];
      };
    }
  ];
}
