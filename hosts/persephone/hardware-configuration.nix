{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/persist" = {
    device = "/dev/disk/by-partlabel/persist";
    fsType = "bcachefs";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
  };

  fileSystems."/nix" = {
    device = "/persist/nix";
    options = [
      "bind"
      "X-fstrim.notrim"
    ];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/swap";
      randomEncryption.enable = true;
    }
  ];

  boot.initrd.systemd.services."bcachefs-unlock@" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecCondition = "";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
