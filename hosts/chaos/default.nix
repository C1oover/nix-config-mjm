{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix

    ./services/jellyfin.nix
    ./services/sabnzbd.nix
    ./services/arr.nix
    ./services/invidious.nix
    ./services/mediaserver-backup.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      jellyfin-ffmpeg = prev.jellyfin-ffmpeg.overrideAttrs (old: {
        configureFlags = builtins.filter (f: f != "--enable-libaribcaption") old.configureFlags;
      });
    })
  ];

  networking.hostName = "chaos";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
      "size=8G"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  fileSystems."/var/lib/private/garage/data" = {
    device = "/dev/disk/by-label/garage";
    fsType = "xfs";
  };

  swapDevices = [
    {
      device = "/nix/swap";
      size = 8 * 1024;
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.consul-agent.enable = true;
  mjm.garage.enable = true;
  mjm.postgresql.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "a87469f6-a653-37ab-8aa4-2a1adeed567f";

  system.stateVersion = "22.11";
}
