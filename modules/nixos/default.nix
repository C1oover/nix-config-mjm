{
  imports = [
    ../common/nushell.nix
    ../common/base

    ./backups.nix
    ./consul-services.nix
    ./desktop
    ./ingress.nix
    ./linkding.nix
    ./server
    ./services.nix
    ./ssh.nix
    ./state.nix
    ./terraform.nix
    ./userborn.nix
    ./vault.nix
    ./vault-agent.nix
    ./vault-secrets.nix
  ];
}
