{
  ingress.virtualHosts = {
    alerts = {
      upstream.service.name = "alertmanager";
    };

    metrics = {
      upstream.service.name = "prometheus";
    };
  };

  vault.policies.prometheus.paths = {
    "kv/data/proxmox".capabilities = [ "read" ];
  };

  vault.approles.roles.leto.tokenPolicies = [ "prometheus" ];
}
