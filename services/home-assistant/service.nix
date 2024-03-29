{
  ingress.virtualHosts.home = {
    upstream.service.name = "home-assistant";
  };

  vault.services.home-assistant.hosts = [ "leto" ];
}
