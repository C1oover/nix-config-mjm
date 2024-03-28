{
  vault.services.netbox.hosts = [ "leto" ];

  ingress.virtualHosts.netbox = {
    upstream.service.name = "netbox";
  };
}
