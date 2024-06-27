{ config, lib, ... }:
let
  inherit (lib) mkIf;

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
  config = mkIf config.mjm.vault.enable {
    terraform.resource.vault_identity_group.admins = {
      name = "admins";
      type = "external";
      policies = [ "admin" ];
    };

    terraform.resource.vault_policy.admin = {
      name = "admin";
      policy = builtins.toJSON {
        path = {
          # read system health check
          "sys/health".capabilities = [
            "read"
            "sudo"
          ];

          # create and manage acl policies across vault
          "sys/policies/acl".capabilities = [ "list" ];
          "sys/policies/acl/*".capabilities = all;

          # enable and manage auth methods across vault
          "auth/*".capabilities = all;
          "sys/auth".capabilities = [ "read" ];
          "sys/auth/*".capabilities = [
            "create"
            "update"
            "delete"
            "sudo"
          ];

          # manage secrets engines
          "sys/mounts".capabilities = [ "read" ];
          "sys/mounts/*".capabilities = all;

          "sys/plugins/catalog/*".capabilities = all;
          "sys/leases/*".capabilities = all;

          "kv/*".capabilities = all;
          "ssh-client-signer/*".capabilities = all;
          "ssh-host-signer/*".capabilities = all;
          "identity/*".capabilities = all;
        };
      };
    };
  };
}
