{
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.framework-13th-gen-intel
    ./hardware-configuration.nix
    ./impermanence.nix
    ./samba.nix
    ./virtualization.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/desktop
    ../common/optional/wireless.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelPackages = pkgs.linuxPackages_testing;
  boot.supportedFilesystems = [
    "btrfs"
    "bcachefs"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.extraModulePackages = [ config.boot.kernelPackages.framework-laptop-kmod ];

  boot.swraid.enable = false;

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  networking.hostName = "persephone";

  services.xserver.displayManager.sddm.wayland.enable = true;

  programs.light.enable = true;

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "matt" ];
  };
  programs._1password.enable = true;

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  hardware.bluetooth.enable = true;

  services.yubikey-agent.enable = true;

  virtualisation.podman.enable = true;

  users.users.matt = {
    extraGroups = [ "video" ];
  };

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
