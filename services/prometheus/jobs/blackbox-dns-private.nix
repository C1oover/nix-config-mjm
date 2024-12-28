{ config, ... }:
let
  cfg = config.mjm.prometheus;
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "blackbox-dns-private";
      metrics_path = "/probe";
      params.module = [ "dns_private" ];
      static_configs = [
        {
          targets = cfg.dnsServers;
          labels = {
            probe_type = "dns";
            probe_scope = "private";
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
