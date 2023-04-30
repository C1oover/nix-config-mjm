{ lib, ... }: {
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [ ];

  hardware.raspberry-pi."4".poe-hat.enable = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
