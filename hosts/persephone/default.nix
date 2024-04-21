{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.hardware.nixosModules.framework-13th-gen-intel
    ./hardware-configuration.nix
    ./virtualization.nix

    ../common/global/nixos
    ../common/users/matt
  ];

  mjm.desktop.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/persist";
    directories = [
      "/home"
      "/nix"
      "/var/log"
      "/var/lib/libvirt"
      "/var/lib/fprint"
      "/var/lib/NetworkManager"
      "/var/lib/iwd"
      "/etc/NetworkManager/system-connections"
      "/etc/secureboot"
    ];
  };
  mjm.wireless.enable = true;

  environment.persistence."/persist".users.matt.directories = lib.mkForce [ ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # boot.kernelPackages = pkgs.linuxPackagesFor (
  #   pkgs.linux_testing.override {
  #     argsOverride = {
  #       modDirVersion = "6.8.0-rc1";
  #       src = pkgs.fetchgit {
  #         url = "https://evilpiepirate.org/git/bcachefs.git";
  #         rev = "9cde7c92bce99069531cccdd6cd3412f3242a289";
  #         hash = "sha256-Jgg0WXIvGJLMJjXIMRKszVw/g+rXK7q9uVx7lNt30wE=";
  #       };
  #     };
  #   }
  # );

  environment.systemPackages = [
    pkgs.sbctl
    config.boot.kernelPackages.perf
  ];

  boot.supportedFilesystems = [
    "btrfs"
    "bcachefs"
  ];

  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  boot.initrd.clevis = {
    enable = true;
    devices."/dev/disk/by-label/persist".secretFile = "${./persist.jwe}";
  };

  boot.extraModulePackages = [ config.boot.kernelPackages.framework-laptop-kmod ];

  boot.swraid.enable = false;

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  networking.hostName = "persephone";

  services.displayManager.sddm.wayland.enable = true;

  # sddm will silently wait 30 sec for a fingerprint after login before timing out
  # i don't want to login with fingerprint anyway (since it wouldn't unlock kwallet)
  security.pam.services.login.fprintAuth = false;

  programs.light.enable = true;

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  hardware.bluetooth.enable = true;

  virtualisation.podman.enable = true;

  users.users.matt = {
    extraGroups = [ "video" ];
  };

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
