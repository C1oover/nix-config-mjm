{
  # hades is the one running the deploy, so we don't want to reboot in
  # the middle of the job.
  deployment.rebootAutomatically = false;

  mjm.username = "mjm";

  networking.hostName = "hades";
  networking.hostId = "8519e7ed";

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "rpool/nixos/root";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/nix" = {
    device = "rpool/nixos/nix";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/home" = {
    device = "rpool/nixos/home";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/bfe9ead3-4309-4518-81eb-3d60406927a1";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  boot.loader.systemd-boot.enable = true;

  nix.settings.max-jobs = 6;

  mjm.consul.enable = true;
  mjm.gitlab-runner.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "or500";
  };
  mjm.server.enable = true;
  mjm.spire.agent.enable = true;
  boot.kernelParams = [ "zfs.zfs_arc_max=7516192768" ];
  boot.zfs.extraPools = [ "slow" ];
  services.zfs.autoScrub.enable = true;

  system.stateVersion = "25.05";
}
