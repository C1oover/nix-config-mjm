{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.mjm.vault.enable {
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

    # as much as I wish this could be defined as a resource, it needs the
    # oidc client secret
    terraform.data.vault_auth_backend.oidc = {
      path = "oidc";
    };

    terraform.resource.vault_jwt_auth_backend_role.default = {
      backend = "\${data.vault_auth_backend.oidc.path}";
      role_name = "default";
      user_claim = "preferred_username";
      groups_claim = "groups";
      oidc_scopes = [
        "groups"
        "email"
        "profile"
      ];
      allowed_redirect_uris = [
        "https://vault.midna.dev/oidc/callback"
        "https://vault.midna.dev/ui/vault/auth/oidc/oidc/callback"
        "http://localhost:8250/oidc/callback"
      ];
    };

    terraform.resource.vault_identity_group_alias.oidc_admins = {
      name = "admins";
      mount_accessor = "\${data.vault_auth_backend.oidc.accessor}";
      canonical_id = "\${vault_identity_group.admins.id}";
    };
  };
}
