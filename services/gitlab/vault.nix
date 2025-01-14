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
  config = mkIf config.mjm.gitlab.enable {
    # can't use `vault.policies` because that will add the policy to the
    # host's approle and this policy is meant for jobs running in CI
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

    terraform.resource.vault_jwt_auth_backend.gitlab = {
      path = "gitlab";
      bound_issuer = "https://git.midna.dev";
      jwks_url = "https://git.midna.dev/oauth/discovery/keys";

      tune = [
        {
          default_lease_ttl = "2h";
          max_lease_ttl = "2h";
          token_type = "default-service";

          # defaults
          allowed_response_headers = [ ];
          audit_non_hmac_request_keys = [ ];
          audit_non_hmac_response_keys = [ ];
          listing_visibility = "hidden";
          passthrough_request_headers = [ ];
        }
      ];
    };

    terraform.resource.vault_jwt_auth_backend_role.homelab_infra = {
      backend = "\${vault_jwt_auth_backend.gitlab.path}";
      role_name = "homelab-infra";
      role_type = "jwt";
      token_policies = [ "\${vault_policy.repo-nix-config.name}" ];
      user_claim = "user_email";
      bound_audiences = [ "http://vault.service.consul:8200" ];
      bound_claims = {
        project_id = "30";
      };
    };
  };
}
