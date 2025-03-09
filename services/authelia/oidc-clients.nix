[
  {
    id = "gitlab";
    description = "GitLab";
    secret = "$pbkdf2-sha512$310000$KBrmIfaP43sBTkOZ5tvwlA$y8/qNNGAeeco48h4vsmtqA73thgVubddQOepMfqG3w0zEvnWPf9w/L8kJpuanGwKtwkejAC.g.M4sQ.Q1qY6OQ";
    public = false;
    authorization_policy = "two_factor";
    redirect_uris = [ "https://git.midna.dev/users/auth/openid_connect/callback" ];
    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];
    userinfo_signing_algorithm = "none";
    token_endpoint_auth_method = "client_secret_basic";
  }
  {
    id = "vault";
    description = "Hashicorp Vault";
    secret = "$pbkdf2-sha512$310000$2Bhvj.sbtzKM5YNygbc7qw$93WKH2CEAacg7BIxVpZtIFnNH60WnMM5GkGeN4w31bQNqW/VX1BU4fMl.ZdA0HCHMtfeCJHIQVJSvCAdG9wjrg";
    public = false;
    authorization_policy = "two_factor";
    redirect_uris = [
      "https://vault.midna.dev/oidc/callback"
      "https://vault.midna.dev/ui/vault/auth/oidc/oidc/callback"
      "http://localhost:8250/oidc/callback"
    ];
    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];
    userinfo_signing_algorithm = "none";
  }
  {
    id = "peertube";
    description = "PeerTube";
    secret = "$pbkdf2-sha512$310000$i/oOcdThnanFjq1JqrACMg$IUGcZqmZZtGOwjfYT1O1ZiMVk634D73XX9qgmwYDtJW3HVcNDRwU9JcX2pJp4WchFkx2iwArh8DWfbU.2xLYiw";
    public = false;
    authorization_policy = "two_factor";
    redirect_uris = [ "https://tube.midna.dev/plugins/auth-openid-connect/router/code-cb" ];
    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];
    userinfo_signing_algorithm = "none";
    response_modes = [ "form_post" ];
  }
]
