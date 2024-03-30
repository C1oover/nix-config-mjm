{
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
}
