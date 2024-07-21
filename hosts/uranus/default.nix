{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  lanzaboote = import inputs.lanzaboote;
in
{
  imports = [
    lanzaboote.nixosModules.lanzaboote

    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ./nvk.nix
  ];

  deployment.phase = null;

  environment.systemPackages = [ pkgs.sbctl ];

  mjm.desktop.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "uranus";
  systemd.network.networks."10-lan".matchConfig.Name = lib.mkForce "enp3*";

  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/71a879cc-7f86-47c7-9dec-1978f0af0e66";
      preLVM = true;
    };
  };

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  services.openssh.enable = true;

  system.stateVersion = "24.05";
}
