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
    terraform.resource.vault_policy.repo-nix-config = {
      name = "repo-nix-config";
      policy = builtins.toJSON {
        path = {
          "kv/data/prod/repos/nix-config".capabilities = [ "read" ];

          "ssh-client-signer/sign/homelab-client".capabilities = [ "update" ];

          "sys/policies/acl/*".capabilities = all;
          "auth/*".capabilities = all;
          "sys/auth/*".capabilities = [
            "create"
            "update"
            "delete"
            "sudo"
          ];
          "sys/auth".capabilities = [ "read" ];
          "sys/mounts/*".capabilities = all;
          "sys/mounts".capabilities = [ "read" ];
          "ssh-client-signer/*".capabilities = all;
          "ssh-host-signer/*".capabilities = all;
          "identity/*".capabilities = all;
        };
      };
    };
  };
}
