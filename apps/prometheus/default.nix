{
  ingress.virtualHosts = {
    alerts = {
      upstream.service.name = "alertmanager";
    };

    metrics = {
      upstream.service.name = "prometheus";
    };
  };

  vault.policies.prometheus = {
    paths = {
      "kv/data/proxmox".capabilities = [ "read" ];
      "kv/data/pagerduty".capabilities = [ "read" ];
    };
    approles = [ "leto" ];
  };
}
