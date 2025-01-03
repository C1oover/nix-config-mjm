{ inputs, ... }:
{
  imports = [
    "${inputs.home-manager}/nixos"
    "${inputs.catppuccin}/modules/nixos"
    (import inputs.lanzaboote).nixosModules.lanzaboote
    (import inputs.proxmox).nixosModules.proxmox-ve

    ../common/nushell.nix

    ../../services

    ./backups.nix
    ./base
    ./consul-services.nix
    ./deployment.nix
    ./desktop
    ./ingress.nix
    ./linkding.nix
    ./raspberrypi
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
