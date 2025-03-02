{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./wireplumber.nix
  ];

  networking.hostName = "uranus";

  mjm.desktop.enable = true;
  mjm.secureboot.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = false;
  systemd.network.networks."10-lan".matchConfig.Name = lib.mkForce "enp3*";

  services.openssh.enable = true;

  services.hardware.bolt.enable = true;

  system.stateVersion = "24.05";
}
