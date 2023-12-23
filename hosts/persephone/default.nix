{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.framework-13th-gen-intel
    ./hardware-configuration.nix
    ./impermanence.nix
    ./samba.nix
    ./snapshots.nix
    ./virtualization.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/desktop
    ../common/optional/wireless.nix
  ];

  nixpkgs.overlays = [inputs.jujutsu.overlays.default];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = ["btrfs"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.consoleLogLevel = 3;
  boot.plymouth = {
    enable = true;
    themePackages = [
      (pkgs.catppuccin-plymouth.override {
        variant = "mocha";
      })
    ];
    theme = "catppuccin-mocha";
  };
  boot.kernelParams = [
    "quiet"
    # catppuccin mocha
    "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
    "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
    "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
  ];

  boot.swraid.enable = false;

  # Allow desktop mouse and keyboard to wake the system
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c24a", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", ATTR{power/wakeup}="enabled"
  '';

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/a8431292-fbf8-4a33-8c5b-b93aae5fe8a7";
    preLVM = true;
  };

  networking.hostName = "persephone";
  services.resolved.enable = true;

  time.timeZone = "America/Denver";

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["matt"];
  };

  programs.steam.enable = true;

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  hardware.bluetooth.enable = true;

  services.yubikey-agent.enable = true;

  virtualisation.podman.enable = true;

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
    keyMap = "us";
  };
  users.users.matt = {
    extraGroups = ["video"];
  };

  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
