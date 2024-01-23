{
  terraform.terraform.required_providers.vault = {
    source = "registry.terraform.io/hashicorp/vault";
    version = ">= 3.0.0";
  };

  terraform.provider.vault = { };

  terraform.resource.vault_identity_group.admins = {
    name = "admins";
    type = "external";
    policies = [ "admin" ];
  };

  vault.databases.enable = true;
  vault.approles.enable = true;

  vault.policies = {
    admin.source = ./policies/admin.hcl;
    consul-template.source = ./policies/consul-template.hcl;
    nomad-server.source = ./policies/nomad-server.hcl;
  };

  ingress.virtualHosts.vault = {
    upstream.service.name = "vault";

    enableAuthProxy = false;
  };
}
