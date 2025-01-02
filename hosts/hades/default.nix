{
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
  mjm.proxmox = {
    enable = true;
    ipAddress = "10.0.2.12";
    managementInterface = "eno1";
    bridgeInterface = "enp2s0";
  };
  mjm.server.enable = true;

  vault-secrets.roleId = "63506e01-0e5a-9dec-0c32-66a0e1f5979d";
  vault-secrets.encryptedSecretId = ''
    k6iUCUh0RJCQyvL8k8q1UyAAAAABAAAADAAAABAAAADsgdgpAdVGArqAY/IAAAAAgAAAAAAAAAALACM
    A0AAAACAAAAAAfgAgTo1kfqiBottdfw/wmlKFSaRA6iOKQGKXVvWrZPBBKwcAEIHjFpazbIKmzZyD76
    hOQVho4bRLf1dcL3q0ab5YdQNbmjElr2UGlgHB3NGUtxZkCzVooR5maKkrYe7loAFu5v3NodwEneCww
    r/3adQdArFrbii0ZeBYFdAjxQBOAAgACwAABBIAILZ6NHyI8C2OPQ54EiEHLXFOjv5568o7GL1lKEe+
    oueoABAAII84KKxFxDK9UzYgDJ7Qn2EIv7+JGy0gWfIh9oK076odtno0fIjwLY49DngSIQctcU6O/nn
    ryjsYvWUoR76i56gAAAAAFMAQuz1wM0GkIa71oxHaJ8f8yqqnz1Q+CLwBi7aQE2VMjalcbyVLvA0TBj
    I+qENm++QUno98LoWoBx18uTj8e3y6mnHhEvpVcPVhrFBa8wCdeIiE
  '';

  system.stateVersion = "25.05";
}
