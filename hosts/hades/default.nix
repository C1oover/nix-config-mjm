{
  imports = [ ./secrets.nix ];

  mjm.username = "mjm";

  networking.hostName = "hades";
  networking.hostId = "8519e7ed";

  services.openiscsi = {
    enable = true;
    name = "iqn.2008-11.org.linux-kvm:2f4af4fd-4b15-4bcb-a2c6-58c8beecd5c1";
  };

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

  mjm.consul.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "or500";
  };
  mjm.proxmox = {
    enable = true;
    ipAddress = "10.0.2.12";
    managementInterface = "eno1";
    bridgeInterface = "enp2s0";
  };
  mjm.server.enable = true;

  system.stateVersion = "25.05";
}
