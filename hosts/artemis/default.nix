{
  imports = [
    ./charmander.nix
    ./charmeleon.nix
    ./charizard.nix
    ./rhyhorn.nix
    ./onix.nix
  ];

  mjm.username = "mjm";

  networking.hostName = "artemis";
  networking.hostId = "88d7144a";

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/e080f992-aa98-474b-abea-971dcc0f75e6";
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
  mjm.networkd.bridge.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "or500";
  };

  system.stateVersion = "25.05";
}
