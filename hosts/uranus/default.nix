{
  pkgs,
  lib,
  ...
}:
{

  deployment.targetHost = null;
  imports = [
    ./hardware-configuration.nix
    ./wireplumber.nix
  ];

  environment.systemPackages = lib.attrValues {
    inherit (pkgs) chrysalis unofficial-homestuck-collection;
  };

  mjm.desktop.enable = true;
  mjm.secureboot.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "uranus";
  networking.networkmanager.enable = false;
  systemd.network.networks."10-lan".matchConfig.Name = lib.mkForce "enp3*";

  services.udev.packages = [ pkgs.chrysalis ];

  services.openssh.enable = true;

  system.stateVersion = "24.05";
}
