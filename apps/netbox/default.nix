{
  vault.approles.roles.leto.tokenPolicies = [ "netbox" ];

  vault.policies.netbox.text = ''
    path "kv/data/netbox" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.netbox = {
    upstream.service.name = "netbox";
  };
}
