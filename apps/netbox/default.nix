{
  vault.databases.roles.netbox = {
    ttl = "long";
  };
  vault.approles.roles.leto.tokenPolicies = ["netbox"];

  vault.policies.netbox.text = ''
    path "database/creds/netbox" {
      capabilities = ["read"]
    }

    path "kv/data/netbox" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.netbox = {
    upstream.service.name = "netbox";
    external = true;
  };
}
