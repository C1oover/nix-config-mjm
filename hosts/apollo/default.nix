{
  imports = [
    ./bulbasaur.nix
    ./dugtrio.nix
    ./ivysaur.nix
    ./primeape.nix
    ./slowbro.nix
    ./venusaur.nix
  ];

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

  mjm.profiles.vm-host.enable = true;

  mjm.microvm-host = {
    enable = true;
    zfsPrefix = "rpool";
  };
  mjm.networkd.macvlan.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "smart500";
  };

  system.stateVersion = "25.05";
}
