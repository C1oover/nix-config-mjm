{ pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/desktop
  ];

  networking.hostName = "uranus";
  systemd.network.networks."10-lan".matchConfig.Name = lib.mkForce "enp3*";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/71a879cc-7f86-47c7-9dec-1978f0af0e66";
      preLVM = true;
    };
  };

  boot.consoleLogLevel = 3;
  boot.plymouth = {
    enable = true;
    themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
    theme = "catppuccin-mocha";
  };
  boot.kernelParams = [
    "quiet"
    # catppuccin mocha
    "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
    "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
    "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  services.resolved.enable = true;
  services.avahi.enable = true;

  time.timeZone = "America/Denver";

  programs.steam.enable = true;

  services.yubikey-agent.enable = true;

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
    keyMap = "us";
  };
  services.openssh.enable = true;

  system.stateVersion = "24.05";
}
