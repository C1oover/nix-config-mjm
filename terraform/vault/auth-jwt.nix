{
  resource.vault_jwt_auth_backend.gitlab = {
    path = "gitlab";
    bound_issuer = "https://git.midna.dev";
    jwks_url = "https://git.midna.dev/-/jwks";

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

  resource.vault_jwt_auth_backend_role.homelab_infra = {
    backend = "\${vault_jwt_auth_backend.gitlab.path}";
    role_name = "homelab-infra";
    role_type = "jwt";
    token_policies = [ "\${vault_policy.gitlab.name}" ];
    user_claim = "user_email";
    bound_claims = {
      project_id = "30";
      ref = "main";
      ref_type = "branch";
    };
  };

  resource.vault_jwt_auth_backend_role.homelab = {
    backend = "\${vault_jwt_auth_backend.gitlab.path}";
    role_name = "homelab";
    role_type = "jwt";
    token_policies = [ "\${vault_policy.gitlab-homelab.name}" ];
    user_claim = "user_email";
    bound_claims = {
      project_id = "2";
      ref = "main";
      ref_type = "branch";
    };
  };
}
