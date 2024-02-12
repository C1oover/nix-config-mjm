{
  vault.approles.roles.leto.tokenPolicies = [ "attic" ];

  vault.policies.attic.text = ''
    path "kv/data/attic" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.attic = {
    upstream.service.name = "attic";
    enableAuthProxy = false;
  };
}
