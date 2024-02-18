{
  ingress.virtualHosts.home = {
    upstream.service.name = "home-assistant";
  };

  vault.policies.home-assistant = {
    paths."kv/data/home-assistant".capabilities = [ "read" ];
    approles = [ "leto" ];
  };
}
