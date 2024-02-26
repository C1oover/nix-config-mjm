{ pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/desktop

    ./nvk.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "uranus";
  systemd.network.networks."10-lan".matchConfig.Name = lib.mkForce "enp3*";

  boot.kernelPackages = pkgs.linuxPackages_6_6;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/71a879cc-7f86-47c7-9dec-1978f0af0e66";
      preLVM = true;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # needed for wayland to work at all
  hardware.nvidia.modesetting.enable = true;

  hardware.opengl.extraPackages = [
    pkgs.libvdpau-va-gl
    pkgs.nvidia-vaapi-driver
  ];

  # without this, discord won't run
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  services.yubikey-agent.enable = true;

  services.openssh.enable = true;

  system.stateVersion = "24.05";
}
