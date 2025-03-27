[
  {
    client_id = "gitlab";
    client_name = "GitLab";
    client_secret = "$pbkdf2-sha512$310000$KBrmIfaP43sBTkOZ5tvwlA$y8/qNNGAeeco48h4vsmtqA73thgVubddQOepMfqG3w0zEvnWPf9w/L8kJpuanGwKtwkejAC.g.M4sQ.Q1qY6OQ";
    public = false;
    authorization_policy = "two_factor";
    redirect_uris = [ "https://git.midna.dev/users/auth/openid_connect/callback" ];
    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_basic";
  }
  {
    client_id = "3oGSHETQNzAa2Hd7CGaBAk08lskEJMKnR7YgMXMgWgqCsl9cWOuWzh2VT5LBu9fA";
    client_name = "Hashicorp Vault";
    client_secret = "$argon2id$v=19$m=65536,t=3,p=4$QSmbERaC2fvE2IJnxScj2w$7TC9He52pllowLCVODoYOc8E1xS6cNrDSwyxvhqZdug";
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
    userinfo_signed_response_alg = "none";
  }
  {
    client_id = "peertube";
    client_name = "PeerTube";
    client_secret = "$pbkdf2-sha512$310000$i/oOcdThnanFjq1JqrACMg$IUGcZqmZZtGOwjfYT1O1ZiMVk634D73XX9qgmwYDtJW3HVcNDRwU9JcX2pJp4WchFkx2iwArh8DWfbU.2xLYiw";
    public = false;
    authorization_policy = "two_factor";
    redirect_uris = [ "https://tube.midna.dev/plugins/auth-openid-connect/router/code-cb" ];
    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];
    userinfo_signed_response_alg = "none";
    response_modes = [ "form_post" ];
  }
  {
    client_id = "Ck6UhnhOFIoo8jYitELDVI7Ys93kIJ6ZGcrLI6xr1YT9PWaIYUQEjc50iqgPSlCz";
    client_name = "Home Assistant";
    client_secret = "$argon2id$v=19$m=65536,t=3,p=4$0IiDX4VOL96OzjoCAdNnZg$iyajs99yFezP4fPw4nH5vnqfOoN04jkN7eVZhNPPweM";
    public = false;
    require_pkce = true;
    pkce_challenge_method = "S256";
    authorization_policy = "two_factor";
    redirect_uris = [ "https://home.midna.dev/auth/oidc/callback" ];
    scopes = [
      "openid"
      "profile"
      "groups"
    ];
    id_token_signed_response_alg = "RS256";
    token_endpoint_auth_method = "client_secret_post";
  }
]
