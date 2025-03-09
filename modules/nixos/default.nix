{
  imports = [
    ../common/nushell.nix

    ../../services

    ./profiles/raspberry-pi
    ./profiles/vm-host.nix

    ./backups.nix
    ./base
    ./consul-services.nix
    ./deployment.nix
    ./desktop
    ./ingress.nix
    ./linkding.nix
    ./qemu-vm.nix
    ./secureboot.nix
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
