{ localModulesPath, ... }:
{
  imports = [
    "${localModulesPath}/nixos/profiles/proxmox-vm.nix"

    ./secrets.nix
  ];

  # hypnos is the one running the deploy, so we don't want to reboot in
  # the middle of the job.
  deployment.rebootAutomatically = false;

  networking.hostName = "hypnos";

  fileSystems."/nix" = {
    device = "/dev/disk/by-partlabel/nix";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-partlabel/swap"; }
    { device = "/dev/disk/by-partlabel/swap2"; }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul.enable = true;
  mjm.gitlab-runner.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/nix/persist";
    tmpfsRoot = {
      enable = true;
      size = "24G";
    };
  };

  system.stateVersion = "22.11";
}
