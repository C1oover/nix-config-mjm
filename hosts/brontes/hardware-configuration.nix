{ lib
, pkgs
, ...
}: {
  boot.kernelPackages = pkgs.linuxPackages_rpi4;
  boot.initrd.availableKernelModules = [ "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # without this config setting, envoy can't run
  # boot.kernelPatches = [
  #   {
  #     name = "pgtables";
  #     patch = null;
  #     extraConfig = ''
  #       PGTABLE_LEVELS 4
  #     '';
  #   }
  # ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
