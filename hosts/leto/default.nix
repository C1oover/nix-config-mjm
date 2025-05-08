{ lib, ... }:
{
  networking.hostName = "leto";

  fileSystems."/persist" = {
    device = "/dev/disk/by-partlabel/persist";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
  };

  fileSystems."/var/lib/private/garage/data" = {
    device = "/dev/disk/by-partlabel/garage";
    fsType = "xfs";
  };

  swapDevices = [ { device = "/dev/disk/by-partlabel/swap"; } ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.profiles.qemu-vm.enable = true;

  mjm.atticd.enable = true;
  mjm.atuin.enable = true;
  mjm.consul.enable = true;
  mjm.garage.enable = true;
  mjm.grafana.enable = true;
  mjm.home-assistant.enable = true;
  mjm.launchpad.enable = true;
  mjm.linkding.enable = true;
  mjm.miniflux.enable = true;
  mjm.netbox.enable = true;
  mjm.paperless.enable = true;
  mjm.prometheus.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot = {
      enable = true;
      size = "8G";
    };
    directories = [
      {
        directory = "/nix";
        inInitrd = true;
      }
    ];
  };
  mjm.vaultwarden.enable = true;

  environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";

  system.stateVersion = "24.05";
}
