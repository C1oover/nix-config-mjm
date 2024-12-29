{
  nushell = ../common/nushell.nix;

  backups = ./backups.nix;
  consul-services = ./consul-services.nix;
  desktop = ./desktop;
  ingress = ./ingress.nix;
  linkding = ./linkding.nix;
  server = ./server;
  services = ./services.nix;
  ssh = ./ssh.nix;
  state = ./state.nix;
  terraform = ./terraform.nix;
  userborn = ./userborn.nix;
  vault = ./vault.nix;
  vault-agent = ./vault-agent.nix;
  vault-secrets = ./vault-secrets.nix;
}
