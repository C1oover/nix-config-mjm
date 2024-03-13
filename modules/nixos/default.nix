{
  bcachefs = import ./bcachefs.nix;
  consul-services = import ./consul-services.nix;
  linkding = import ./linkding.nix;
  vault-agent = import ./vault-agent.nix;
  vault-secrets = import ./vault-secrets.nix;
}
