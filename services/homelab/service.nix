{
  ingress.virtualHosts.homelab = {
    upstream.service.name = "homelab";
  };

  vault.services.homelab = {
    commonPolicies = [ "backups" ];
    hosts = [ "leto" ];
  };
}
