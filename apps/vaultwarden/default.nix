{
  ingress.virtualHosts.pass = {
    upstream.service.name = "vaultwarden";

    enableAuthProxy = false;
  };

  vault.policies.vaultwarden = {
    paths."kv/data/vaultwarden".capabilities = [ "read" ];
    approles = [ "leto" ];
  };
}
