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

  # TODO consider if this should be in services/
  # remote builder key
  users.users.matt.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHWS7+ecqC11q28WuizDlFuiEYEro1gv2ZtN4fs4hayg"
  ];

  system.stateVersion = "21.03";
}
