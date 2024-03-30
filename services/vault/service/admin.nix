let
  all = [
    "create"
    "read"
    "update"
    "delete"
    "list"
    "sudo"
  ];
in
{
  terraform.resource.vault_identity_group.admins = {
    name = "admins";
    type = "external";
    policies = [ "admin" ];
  };

  vault.policies.admin = {
    # read system health check
    paths."sys/health".capabilities = [
      "read"
      "sudo"
    ];

    # create and manage acl policies across vault
    paths."sys/policies/acl".capabilities = [ "list" ];
    paths."sys/policies/acl/*".capabilities = all;

    # enable and manage auth methods across vault
    paths."auth/*".capabilities = all;
    paths."sys/auth".capabilities = [ "read" ];
    paths."sys/auth/*".capabilities = [
      "create"
      "update"
      "delete"
      "sudo"
    ];

    # manage secrets engines
    paths."sys/mounts".capabilities = [ "read" ];
    paths."sys/mounts/*".capabilities = all;

    paths."sys/plugins/catalog/*".capabilities = all;
    paths."sys/leases/*".capabilities = all;

    paths."kv/*".capabilities = all;
    paths."ssh-client-signer/*".capabilities = all;
    paths."ssh-host-signer/*".capabilities = all;
    paths."identity/*".capabilities = all;
  };
}
