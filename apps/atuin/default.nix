{
  vault.databases.roles.atuin = {
    ttl = "short";
  };

  vault.policies.atuin.text = ''
    path "database/creds/atuin" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.atuin = {
    upstream.service.name = "atuin";
    enableAuthProxy = false;
  };
}
