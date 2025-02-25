{
  imports = [ ./secrets.nix ];

  mjm.username = "mjm";

  networking.hostName = "artemis";
  networking.hostId = "88d7144a";

  services.openiscsi = {
    enable = true;
    name = "iqn.2008-11.org.linux-kvm:838a2416-b09c-44bb-9a02-55728f537b29";
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
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
    device = "/dev/disk/by-partuuid/e080f992-aa98-474b-abea-971dcc0f75e6";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  boot.loader.systemd-boot.enable = true;

  mjm.consul.enable = true;
  mjm.libvirtd.enable = true;
  mjm.nut = {
    enable = true;
    connectedUPSName = "or500";
  };
  mjm.proxmox = {
    enable = true;
    ipAddress = "10.0.2.10";
    managementInterface = "enp1s0";
    bridgeInterface = "enp2s0";
  };
  mjm.remote-builder.enable = true;
  mjm.server.enable = true;

  system.stateVersion = "25.05";
}
