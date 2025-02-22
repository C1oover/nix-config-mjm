{
  imports = [ ./secrets.nix ];

  networking.hostName = "arges";

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
    neededForBoot = true;
  };

  swapDevices = [
    {
      device = "/persist/swap";
      size = 20 * 1024;
    }
  ];

  mjm.consul.enable = true;
  mjm.nut = {
    enable = true;
    mode = "server";
  };
  mjm.raspberrypi.enable = true;
  mjm.remote-builder.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot = {
      enable = true;
      size = "20G";
    };
    directories = [
      "/boot"
      {
        directory = "/nix";
        inInitrd = true;
      }
    ];
  };

  system.stateVersion = "21.03";
}
