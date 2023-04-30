{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/consul-agent.nix
    ../common/optional/nomad-client.nix
  ];

  networking.hostName = "arges";

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # no, I don't know why the interface name is different from brontes.
  services.consul.interface.advertise = "eth0";

  system.stateVersion = "21.03";
}
