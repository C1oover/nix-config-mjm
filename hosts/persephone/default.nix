{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/desktop
    ../common/optional/wireless.nix
  ];

  x.nixvim.enableIde = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = ["btrfs"];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    # catppuccin mocha
    "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
    "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
    "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
  ];

  boot.blacklistedKernelModules = ["hid-sensor-hub"];

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/a8431292-fbf8-4a33-8c5b-b93aae5fe8a7";
    preLVM = true;
  };

  networking.hostName = "persephone";

  # Set your time zone.
  time.timeZone = "America/Denver";

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["matt"];
  };

  programs.steam.enable = true;

  services.fwupd.enable = true;
  services.fprintd.enable = true;

  programs.nixvim.clipboard.providers.wl-copy.enable = true;

  services.yubikey-agent.enable = true;

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u32n.psf.gz";
    keyMap = "us";
  };
  users.mutableUsers = false;
  users.users.matt = {
    isNormalUser = true;
    extraGroups = ["wheel" "video"];
    hashedPassword = "$6$JhSUuIask83mtadB$iV5I3SmQE13rVV08RpCN4Ho09VvpmCm6xouZ2o7/1rhR63YFh/WtLAdM1f2P4hgJrxi.ss2zh53xpbSqx/zy9/";
  };

  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
