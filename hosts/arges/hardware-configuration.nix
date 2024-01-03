{lib, ...}: {
  imports = [
    ../common/optional/poe-hat.nix
  ];

  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "mode=755"];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = ["noatime"];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/persist/boot";
    options = ["bind" "X-fstrim.notrim"];
  };

  fileSystems."/nix" = {
    device = "/persist/nix";
    options = ["bind" "X-fstrim.notrim"];
  };

  swapDevices = [
    {device = "/persist/swap";}
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
