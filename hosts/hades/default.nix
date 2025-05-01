{
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

  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/bfe9ead3-4309-4518-81eb-3d60406927a1";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  boot.loader.systemd-boot.enable = true;

  mjm.profiles.vm-host.enable = true;

  mjm.networkd.bridge.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "or500";
  };

  system.stateVersion = "25.05";
}
