{
  networking.hostName = "steropes";

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
    neededForBoot = true;
  };

  swapDevices = [
    {
      device = "/persist/swap";
      size = 8 * 1024;
    }
  ];

  mjm.profiles.raspberry-pi.enable = true;

  mjm.consul.enable = true;
  mjm.ingress.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "or500";
  };
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot.enable = true;
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
