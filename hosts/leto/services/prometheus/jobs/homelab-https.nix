{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "homelab-https";
      metrics_path = "/probe";
      params.module = ["https_homelab"];
      static_configs = [
        {
          targets = [
            "alerts.midna.dev"
            "auth.midna.dev"
            "consul.midna.dev"
            "metrics.midna.dev"
            "nomad.midna.dev"
            "vault.midna.dev"
            "authelia.home.mattmoriarity.com"
            "grafana.home.mattmoriarity.com"
            "homelab.home.mattmoriarity.com"
            "adminer.home.mattmoriarity.com"
          ];
        }
      ];
      relabel_configs = [
        {
          source_labels = ["__address__"];
          target_label = "__param_target";
        }
        {
          source_labels = ["__param_target"];
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
