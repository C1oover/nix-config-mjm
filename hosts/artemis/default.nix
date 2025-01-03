{
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
  mjm.server.enable = true;

  vault-secrets.roleId = "e261b0b4-c938-7e0f-1242-02a92bda9b97";
  vault-secrets.encryptedSecretId = ''
    k6iUCUh0RJCQyvL8k8q1UyAAAAABAAAADAAAABAAAABBCsD6hoY9Hn2bwmcAAAAAgAAAAAAAAAALACM
    A0AAAACAAAAAAfgAg3jNtVihGE8sTidBFl/f9qV69chv+loNALPezMtvROD0AECWLPTMj7qK2DKnFvH
    /tEHRLHF4mhX99xGIEzW5ZJ5IHKKbtk7Mg0q129dmscEn6rN6+vBJO9tR4geXreMLThW/Q5V2M3zGqk
    /LUBBWjkQCvDnn08ZdSOBcxRwBOAAgACwAABBIAIO8Js+49Ne5j7UQ1na4Om0HlDQ6xAYGD7EkQR2g8
    RHBEABAAIA1/S03YcoyCvEEVGXzJP3f1kLJIG1hgcuyfLhvP9sng7wmz7j017mPtRDWdrg6bQeUNDrE
    BgYPsSRBHaDxEcEQAAAAA0LlPPSkAfYQSthMwRW2izVfTLqTYinPWhYc72rK+TMwzsNOvLlyIUINSe7
    MZ0pum6aU1Bk6hxFBPpnTWxiVLhecSKljAgbajSVRzKCusJkv+Q3Y/
  '';

  system.stateVersion = "25.05";
}
