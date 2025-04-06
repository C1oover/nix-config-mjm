{
  networking.hostName = "helios";

  fileSystems."/nix" = {
    # not using by-partlabel because this disk doesn't have a GPT partition
    # table, and converting it to one may be destructive.
    device = "/dev/disk/by-label/nixos";
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

  mjm.profiles.qemu-vm.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul.enable = true;
  mjm.garage.enable = true;
  mjm.matrix-server.enable = true;
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
