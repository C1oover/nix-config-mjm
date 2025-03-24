{
  imports = [
    ../common/nushell.nix

    ../../services

    ./profiles/qemu-vm.nix
    ./profiles/raspberry-pi
    ./profiles/vm-host.nix

    ./backups.nix
    ./base
    ./consul-services.nix
    ./deployment.nix
    ./desktop
    ./ingress.nix
    ./linkding.nix
    ./secureboot.nix
    ./server
    ./services.nix
    ./ssh.nix
    ./state.nix
    ./userborn.nix
    ./vault.nix
    ./vault-agent.nix
    ./vault-secrets.nix
  ];
}
