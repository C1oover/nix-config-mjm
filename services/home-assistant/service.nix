{
  ingress.virtualHosts.home = {
    upstream.service.name = "home-assistant";
  };

  vault.services.home-assistant = {
    commonPolicies = [ "backups" ];
    hosts = [ "leto" ];
  };
}
