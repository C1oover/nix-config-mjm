{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix

    ./services/conduit.nix
    ./services/mautrix-discord.nix
    ./services/mautrix-slack.nix
    ./services/heisenbridge.nix
  ];

  networking.hostName = "helios";

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
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "61d175e1-7a2e-4554-2cca-cff48c926b82";

  system.stateVersion = "22.11";
}
