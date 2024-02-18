{
  vault.policies.netbox = {
    paths."kv/data/netbox".capabilities = [ "read" ];
    approles = [ "leto" ];
  };

  ingress.virtualHosts.netbox = {
    upstream.service.name = "netbox";
  };
}
