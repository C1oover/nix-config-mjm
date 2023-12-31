{
  vault.databases.roles.guacamole = {
    ttl = "long";
  };
  vault.approles.roles.guacamole = {};

  vault.policies.guacamole.text = ''
    path "ssh-client-signer/sign/homelab-client" {
      capabilities = ["update"]
    }

    path "database/creds/guacamole" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts.guacamole = {
    upstream = {
      service.name = "guacamole";
      path = "/guacamole/";
    };
  };
}
