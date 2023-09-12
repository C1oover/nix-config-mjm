{
  vault.databases.roles.atuin = {};

  vault.policies.atuin.text = ''
    path "database/creds/atuin" {
      capabilities = ["read"]
    }
  '';
}
