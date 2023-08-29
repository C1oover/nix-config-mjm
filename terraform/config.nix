{
  imports = [
    ./modules

    ./vault
    ./vault/auth-jwt.nix
    ./vault/auth-oidc.nix
    ./vault/auth-github.nix
    ./vault/pki-homelab.nix
    ./vault/kv.nix
    ./vault/ssh-homelab-client.nix

    ./apps
  ];

  terraform.backend.consul = {
    scheme = "http";
    access_token = "";
    datacenter = "dc1";
    path = "terraform/state";
  };
}
