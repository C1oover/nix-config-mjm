{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt
  ];

  networking.hostName = "brontes";

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  system.stateVersion = "21.03";
}
