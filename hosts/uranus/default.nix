{
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  deployment.targetHost = null;

  environment.systemPackages = lib.attrValues {
    inherit (pkgs) chrysalis sbctl;

    fix-audio = pkgs.writeNuBin "fix-audio" ./fix-audio.nu;
  };

  mjm.desktop.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

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
      device = "/dev/disk/by-partlabel/root";
      preLVM = true;
    };
  };

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';
  services.udev.packages = [ pkgs.chrysalis ];

  services.openssh.enable = true;

  system.stateVersion = "24.05";
}
