{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "homelab-https";
      metrics_path = "/probe";
      params.module = [ "https_homelab" ];
      static_configs = [
        {
          targets = [
            "authelia.home.mattmoriarity.com"
            "consul.home.mattmoriarity.com"
            "nomad.home.mattmoriarity.com"
            "vault.home.mattmoriarity.com"
            "prometheus.home.mattmoriarity.com"
            "alertmanager.home.mattmoriarity.com"
            "grafana.home.mattmoriarity.com"
            "paperless.home.mattmoriarity.com"
            "homelab.home.mattmoriarity.com"
            "livebook.home.mattmoriarity.com"
            "adminer.home.mattmoriarity.com"
          ];
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = [ "__param_target" ];
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "blackbox-exporter.service.consul:9115";
        }
      ];
    }
  ];
}
