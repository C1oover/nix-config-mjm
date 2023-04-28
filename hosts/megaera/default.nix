{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt
  ];

  networking.hostName = "megaera";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  system.stateVersion = "22.11";
}
