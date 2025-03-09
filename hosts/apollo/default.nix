{
  imports = [ ./secrets.nix ];

  mjm.username = "mjm";

  networking.hostName = "apollo";
  networking.hostId = "fb53aded";

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

  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/6c361b54-107a-4737-9444-646836c22c05";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  boot.loader.systemd-boot.enable = true;

  mjm.profiles.vm-host = {
    enable = true;
    managementInterface = "enp0s31f6";
    bridgeInterface = "enp3s0";
    iscsiName = "iqn.2008-11.org.linux-kvm:9db00d91-7252-419a-83e6-0e0ad67635e4";
  };

  mjm.nut = {
    enable = true;
    connectedUPSName = "smart500";
  };

  system.stateVersion = "25.05";
}
