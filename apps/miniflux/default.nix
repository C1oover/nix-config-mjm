{
  vault.databases.roles.miniflux = {
    ttl = "short";
  };

  vault.policies.miniflux.text = ''
    # Allow miniflux to read credentials for accessing its database
    path "database/creds/miniflux" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.feeds = {
    upstream.service.name = "miniflux";
  };
}
