{
  imports = [ ./secrets.nix ];

  mjm.username = "mjm";

  networking.hostName = "apollo";
  networking.hostId = "fb53aded";

  services.openiscsi = {
    enable = true;
    name = "iqn.2008-11.org.linux-kvm:9db00d91-7252-419a-83e6-0e0ad67635e4";
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sr_mod"
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
    device = "/dev/disk/by-partuuid/6c361b54-107a-4737-9444-646836c22c05";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  boot.loader.systemd-boot.enable = true;

  mjm.consul.enable = true;
  mjm.libvirtd = {
    enable = true;
    managementInterface = "enp0s31f6";
    bridgeInterface = "enp3s0";
  };
  mjm.nut = {
    enable = true;
    connectedUPSName = "smart500";
  };
  mjm.remote-builder.enable = true;
  mjm.server.enable = true;

  system.stateVersion = "25.05";
}
