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

  nixpkgs.overlays = [ inputs.jujutsu.overlays.default ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelPackages = pkgs.linuxPackages_testing;
  boot.supportedFilesystems = [
    "btrfs"
    "bcachefs"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  boot.extraModulePackages = [ config.boot.kernelPackages.framework-laptop-kmod ];

  boot.swraid.enable = false;

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  boot.initrd.systemd.enable = true;

  networking.hostName = "persephone";
  services.resolved.enable = true;
  services.avahi.enable = true;

  time.timeZone = "America/Denver";

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "matt" ];
  };
  programs._1password.enable = true;

  programs.steam.enable = true;

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  hardware.bluetooth.enable = true;

  services.yubikey-agent.enable = true;

  virtualisation.podman.enable = true;

  systemd.oomd = {
    enableRootSlice = true;
    enableUserSlices = true;
  };

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
    keyMap = "us";
  };
  users.users.matt = {
    extraGroups = [ "video" ];
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    # temp fix for yubikey-agent: https://github.com/NixOS/nixpkgs/pull/281421
    pcscliteWithPolkit.out
  ];

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
