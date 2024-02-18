{
  vault.policies.attic = {
    paths."kv/data/attic".capabilities = [ "read" ];
    approles = [ "leto" ];
  };

  ingress.virtualHosts.attic = {
    upstream.service.name = "attic";
    enableAuthProxy = false;
  };
}
