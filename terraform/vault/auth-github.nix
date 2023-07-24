{
  resource.vault_github_auth_backend.github_auth = {
    organization = "mmoriarity";
  };

  resource.vault_github_user.mjm = {
    backend = "\${vault_github_auth_backend.github_auth.id}";
    user = "mjm";
    policies = ["admin"];
  };
}
