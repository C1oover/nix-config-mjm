{
  imports = [
    ./secrets.nix
  ];

  networking.hostName = "chaos";

  fileSystems."/nix" = {
    device = "/dev/disk/by-partlabel/nix";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
  };

  fileSystems."/var/lib/private/garage/data" = {
    device = "/dev/disk/by-partlabel/garage";
    fsType = "xfs";
  };

  swapDevices = [
    {
      device = "/nix/swap";
      size = 8 * 1024;
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.profiles.qemu-vm.enable = true;

  mjm.consul.enable = true;
  mjm.garage.enable = true;
  mjm.icloudpd.enable = true;
  mjm.media-server.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/nix/persist";
    tmpfsRoot = {
      enable = true;
      size = "8G";
    };
  };

  system.stateVersion = "22.11";
}
