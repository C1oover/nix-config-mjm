{
  nushell = ../common/nushell.nix;

  consul-services = ./consul-services.nix;
  ingress = ./ingress.nix;
  linkding = ./linkding.nix;
  services = ./services.nix;
  ssh = ./ssh.nix;
  terraform = ./terraform.nix;
  userborn = ./userborn.nix;
  vault = ./vault.nix;
  vault-agent = ./vault-agent.nix;
  vault-secrets = ./vault-secrets.nix;
}
