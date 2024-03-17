{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b8bd95ad-1c46-4d01-a218-5d55faf9457e";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/ad2b74bf-9d61-490d-bd0b-e94ea13d7450"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
