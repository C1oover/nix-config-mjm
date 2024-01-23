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
  }
  {
    id = "vault";
    description = "Hashicorp Vault";
    secret = "$pbkdf2-sha512$310000$GcSGTc2f7qUrSu9cM1cGvQ$IJ.jX/HZx3lVujQbbdCp66vm2qWX8M6MEK1peMeTI1GZxMWaVRlVC59tGkIW08ij6WliBEfTvSTSToKmXYEGTQ";
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
    id = "proxmox";
    description = "Proxmox Virtual Environment";
    secret = "$pbkdf2-sha512$310000$jSR5KT8pbsKrYovaP0RYhA$pt40j9SHmF3SfZPgxGfmQZKfS.07Zks7MkmCHuAzJaEOY0Gca1CzvFwczMWhFHiRTd1tOsLzKY1yGAdYb1Q9sA";
    public = false;
    authorization_policy = "two_factor";
    redirect_uris = [
      "https://10.0.2.10:8006"
      "https://10.0.2.11:8006"
      "https://artemis.home.mattmoriarity.com:8006"
      "https://apollo.home.mattmoriarity.com:8006"
      "https://proxmox.midna.dev"
    ];
    scopes = [
      "openid"
      "profile"
      "email"
    ];
    userinfo_signing_algorithm = "none";
  }
  {
    id = "minio";
    description = "MinIO";
    secret = "$pbkdf2-sha512$310000$lIbZcunKd9pcd.e/8.8esw$lJY3Zb7Ng8eSKHXV3xI9BA2THWMy7ZcCPYX/pCjuLw32nxN4stMnnIXb8poFbX8DFxvrWHT5sPeRWFl532RxHg";
    public = false;
    authorization_policy = "two_factor";
    redirect_uris = [ "https://minio-console.midna.dev/oauth_callback" ];
    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];
    userinfo_signing_algorithm = "none";
  }
]
