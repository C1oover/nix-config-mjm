{
  vault.databases.roles.linkding = {
    ttl = "long";
  };

  vault.policies.linkding.text = ''
    path "database/creds/linkding" {
      capabilities = ["read"]
    }
  '';

  vault.approles.roles.leto.tokenPolicies = ["linkding"];

  ingress.virtualHosts.links = {
    upstream.service.name = "linkding";
  };
}
