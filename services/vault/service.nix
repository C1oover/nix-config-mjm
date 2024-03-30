{
  imports = [
    ./service/admin.nix
    ./service/backup.nix

    ./service/auth/github.nix
    ./service/auth/jwt.nix
    ./service/auth/oidc.nix

    ./service/mounts/kv.nix
    ./service/mounts/ssh-client-signer.nix
  ];

  terraform.terraform.required_providers.vault = {
    source = "registry.terraform.io/hashicorp/vault";
    version = ">= 3.0.0";
  };

  terraform.provider.vault = { };

  vault.approles.enable = true;

  ingress.virtualHosts.vault = {
    upstream.service.name = "vault";

    enableAuthProxy = false;
  };
}
