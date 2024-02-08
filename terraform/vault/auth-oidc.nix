{
  data.vault_auth_backend.oidc = {
    path = "oidc";
  };

  resource.vault_jwt_auth_backend_role.default = {
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
      "https://vault.home.mattmoriarity.com/oidc/callback"
      "https://vault.home.mattmoriarity.com/ui/vault/auth/oidc/oidc/callback"
      "https://vault.midna.dev/oidc/callback"
      "https://vault.midna.dev/ui/vault/auth/oidc/oidc/callback"
      "http://localhost:8250/oidc/callback"
    ];
  };

  resource.vault_identity_group_alias.oidc_admins = {
    name = "admins";
    mount_accessor = "\${data.vault_auth_backend.oidc.accessor}";
    canonical_id = "\${vault_identity_group.admins.id}";
  };
}
