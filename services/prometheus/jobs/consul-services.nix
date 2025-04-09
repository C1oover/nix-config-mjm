{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "consul-services";
      consul_sd_configs = [ { server = "127.0.0.1:8500"; } ];
      tls_config = {
        ca_file = "/var/cache/prometheus/bundle.pem";
        cert_file = "/var/cache/prometheus/cert.pem";
        key_file = "/var/cache/prometheus/key.pem";
        # annoying, but we don't have IPs in the certs, so the server name check will fail
        insecure_skip_verify = true;
      };
      relabel_configs = [
        {
          source_labels = [ "__meta_consul_service_metadata_metrics_path" ];
          action = "keep";
          regex = "(.+)";
        }
        {
          source_labels = [ "__meta_consul_service_metadata_metrics_path" ];
          target_label = "__metrics_path__";
          regex = "(.+)";
        }
        {
          source_labels = [ "__meta_consul_service" ];
          target_label = "service_name";
          regex = "(.+)";
        }
        {
          source_labels = [ "service_name" ];
          target_label = "service_name";
          regex = "(.+)-metrics";
        }
        {
          source_labels = [ "__meta_consul_node" ];
          target_label = "node_name";
          regex = "(.+)";
        }
        {
          source_labels = [
            "__address__"
            "__meta_consul_service_metadata_metrics_port"
          ];
          regex = "([^:]+)(?::\\d+)?;(\\d+)";
          replacement = "$1:$2";
          target_label = "__address__";
        }
        {
          source_labels = [
            "__address__"
            "__meta_consul_service_metadata_metrics_port"
          ];
          regex = "(\\[[^\\]]+\\])(?::\\d+)?;(\\d+)";
          replacement = "$1:$2";
          target_label = "__address__";
        }
        {
          source_labels = [ "__meta_consul_service_id" ];
          target_label = "instance";
          regex = "(.+)";
        }
        {
          source_labels = [ "__meta_consul_service_metadata_metrics_scheme" ];
          target_label = "__scheme__";
          regex = "(.+)";
        }
      ];
    }
  ];
}
