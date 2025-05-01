{
  imports = [
    ../common/nushell.nix

    ../../services

    ./profiles/microvm.nix
    ./profiles/qemu-vm.nix
    ./profiles/raspberry-pi
    ./profiles/vm-host.nix

    ./backups.nix
    ./base
    ./conduwuit.nix
    ./consul-services.nix
    ./deployment.nix
    ./desktop
    ./ingress.nix
    ./linkding.nix
    ./microvm-host.nix
    ./secureboot.nix
    ./server
    ./services.nix
    ./ssh.nix
    ./state.nix
    ./userborn.nix
    ./vault.nix
  ];
}
