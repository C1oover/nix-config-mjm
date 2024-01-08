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
    options = ["defaults" "mode=755" "size=20G"];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = ["noatime"];
    neededForBoot = true;
  };

  swapDevices = [
    {
      device = "/persist/swap";
      size = 20 * 1024;
    }
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
