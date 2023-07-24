{
  provider.vault = {};

  resource.vault_identity_group.admins = {
    name = "admins";
    type = "external";
    policies = ["admin"];
  };

  vault.databases.enable = true;
  vault.approles.enable = true;

  vault.policies = {
    admin.source = ./policies/admin.hcl;
    consul-template.source = ./policies/consul-template.hcl;
    nomad-server.source = ./policies/nomad-server.hcl;
  };
}
