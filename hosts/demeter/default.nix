{
  imports = [ ./secrets.nix ];

  mjm.username = "mjm";

  networking.hostName = "demeter";
  networking.hostId = "044faaed";

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.enableRedistributableFirmware = true;

  # the tpm doesn't seem to work right on this one
  boot.initrd.systemd.tpm2.enable = false;
  systemd.targets.tpm2.enable = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems = {
    "/" = {
      device = "boot-pool/nixos/root";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/nix" = {
      device = "boot-pool/nixos/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/home" = {
      device = "boot-pool/nixos/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/var" = {
      device = "boot-pool/nixos/var";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };
    "/boot" = {
      device = "/dev/disk/by-partuuid/8ba4b6e4-c4be-457b-88ab-a7bd84af6b9f";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/c7a322af-2294-4859-bee2-6112e7fe9960";
      randomEncryption = true;
    }
  ];

  mjm.consul.enable = true;
  mjm.libvirtd = {
    enable = true;
    bridgeInterface = "enp0s31f6";
  };
  mjm.nas.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "smart500";
  };
  mjm.server.enable = true;

  system.stateVersion = "25.05";
}
