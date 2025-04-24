{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  mjm.username = "mjm";

  networking.hostName = "niobe";
  networking.domain = "midna.dev";

  boot.initrd.availableKernelModules = [
    "virtio_scsi"
    "sr_mod"
  ];

  fileSystems."/persist" = {
    device = "/dev/disk/by-partlabel/persist";
    fsType = "xfs";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    {
      device = "/persist/swap";
      size = 24 * 1024;
    }
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  deployment.targetHost = "152.53.116.186";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-primary-lan".enable = false;
    networks."10-wan" = {
      matchConfig.Name = "lan0";
      networkConfig.DHCP = "ipv4";
      address = [ "2a0a:4cc0:c0:3843::1/64" ];
      routes = [ { Gateway = "fe80::1"; } ];
    };
  };

  mjm.remote-builder.enable = true;
  mjm.server = {
    enable = true;
    enableAlloy = false;
    enableSSHHostCert = false;
  };
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot = {
      enable = true;
      size = "24G";
    };
    directories = [
      {
        directory = "/nix";
        inInitrd = true;
      }
    ];
  };

  system.stateVersion = "25.05";
}
