{
  imports = [
    ../common/global/nixos
    ../common/users/matt

    ../common/optional/proxmox-vm.nix

    ./services/actual.nix
    ./services/attic.nix
    ./services/atuin.nix
    ./services/homelab.nix
    ./services/home-assistant.nix
    ./services/linkding.nix
    ./services/miniflux.nix
    ./services/netbox.nix
    ./services/paperless.nix
    ./services/taskserver.nix
    ./services/vaultwarden.nix
  ];

  networking.hostName = "leto";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "mode=755"
      "size=8G"
    ];
  };

  fileSystems."/persist" = {
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

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mjm.authelia.enable = true;
  mjm.consul.enable = true;
  mjm.garage.enable = true;
  mjm.grafana.enable = true;
  mjm.postgresql.enable = true;
  mjm.prometheus.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/persist";
    directories = [ "/nix" ];
  };

  vault-secrets.roleId = "29829ea8-3eb2-b3d6-8aab-d150dbb48e3d";

  system.stateVersion = "24.05";
}
