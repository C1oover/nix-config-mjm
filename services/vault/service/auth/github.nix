{
  # TODO maybe remove this, I prefer to use OIDC

  terraform.resource.vault_github_auth_backend.github_auth = {
    organization = "mmoriarity";
  };

  terraform.resource.vault_github_user.mjm = {
    backend = "\${vault_github_auth_backend.github_auth.id}";
    user = "mjm";
    policies = [ "admin" ];
  };
}
