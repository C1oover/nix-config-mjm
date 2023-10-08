{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-laptop
    inputs.hardware.nixosModules.common-pc-laptop-ssd
    ./hardware-configuration.nix
    ./impermanence.nix
    ./snapshots.nix
    ./virtualization.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/desktop
    ../common/optional/wireless.nix
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = ["btrfs"];

  # Use the systemd-boot EFI boot loader.
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
    "mem_sleep_default=deep"
    "nvme.noacpi=1"
    "quiet"
    # catppuccin mocha
    "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
    "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
    "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
  ];

  boot.blacklistedKernelModules = ["hid-sensor-hub"];
  boot.swraid.enable = false;

  # Further tweak to ensure the brightness and airplane mode keys work
  # https://community.frame.work/t/responded-12th-gen-not-sending-xf86monbrightnessup-down/20605/67
  systemd.services.bind-keys-driver = {
    description = "Bind brightness and airplane mode keys to their driver";
    wantedBy = ["default.target"];
    after = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      ls -lad /sys/bus/i2c/devices/i2c-*:* /sys/bus/i2c/drivers/i2c_hid_acpi/i2c-*:*
      if [ -e /sys/bus/i2c/devices/i2c-FRMW0001:00 -a ! -e /sys/bus/i2c/drivers/i2c_hid_acpi/i2c-FRMW0001:00 ]; then
        echo fixing
        echo i2c-FRMW0001:00 > /sys/bus/i2c/drivers/i2c_hid_acpi/bind
        ls -lad /sys/bus/i2c/devices/i2c-*:* /sys/bus/i2c/drivers/i2c_hid_acpi/i2c-*:*
        echo done
      else
        echo no fix needed
      fi
    '';
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/a8431292-fbf8-4a33-8c5b-b93aae5fe8a7";
    preLVM = true;
  };

  networking.hostName = "persephone";
  services.resolved.enable = true;

  # Set your time zone.
  time.timeZone = "America/Denver";

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["matt"];
  };

  programs.steam.enable = true;

  services.fwupd.enable = true;
  services.fprintd.enable = true;
  services.hardware.bolt.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.yubikey-agent.enable = true;

  virtualisation.podman.enable = true;

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
