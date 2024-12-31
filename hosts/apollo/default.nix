{
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
  mjm.proxmox = {
    enable = true;
    ipAddress = "10.0.2.11";
    managementInterface = "enp0s31f6";
    bridgeInterface = "enp3s0";
  };
  mjm.server.enable = true;

  vault-secrets.roleId = "4c879c3b-6e15-f0b8-5cff-265af8a09beb";
  vault-secrets.encryptedSecretId = ''
    k6iUCUh0RJCQyvL8k8q1UyAAAAABAAAADAAAABAAAACnevIarzRL7bn9WAcAAAAAgAAAAAAAAAALACM
    A0AAAACAAAAAAfgAgCOtMSEncLOkb3pHTi+h/o1H9hzWNtEfnSu0KIp6HprkAEBu6iylg7AKXonE3AD
    HVb8ize3dq/CsFIOKHIBIoSVB6RjsTdDZVM21VKYTWfBqr+2CddS65VF2HdFopMiw0jhEbuHeHRgwKU
    9k4mva58gsSLU/cmvRLDbnLQABOAAgACwAABBIAIHpFbuyIlIm6SjGhX+yahbFEA9NOZWPyy3QdrJpU
    rjBwABAAIJYVJ8HckYa1JaNS+zBZ9BckDZC5mz1Ga5g/b9AvJALXekVu7IiUibpKMaFf7JqFsUQD005
    lY/LLdB2smlSuMHAAAAAAnMD6CVuOkfrZaBBHtVggGJ6q75ucYpyew11/zmA45iGM2WY7Z0KBIMhoLt
    5tLimld4dfBaA6qfx5c8Q53c12PuXVZOxzI0ZxZzdCy02PE0jx5kLS
  '';

  system.stateVersion = "25.05";
}
