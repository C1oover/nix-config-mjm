{
  imports = [
    ./secrets.nix
  ];

  mjm.username = "mjm";

  networking.hostName = "melinoe";

  fileSystems."/persist" = {
    device = "/dev/disk/by-partlabel/persist";
    fsType = "xfs";
    options = [ "noatime" ];
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
      size = 8 * 1024;
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.profiles.qemu-vm.enable = true;

  mjm.consul.enable = true;
  mjm.gitlab.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot = {
      enable = true;
      size = "8G";
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
