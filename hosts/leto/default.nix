{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/garage

    ./services/actual.nix
    ./services/attic.nix
    ./services/authelia
    ./services/home-assistant.nix
    ./services/linkding.nix
    ./services/lldap.nix
    ./services/netbox.nix
    ./services/paperless.nix
    ./services/postgresql.nix
    ./services/prometheus
    ./services/taskserver.nix
    ./services/vault-agent.nix
    ./services/vaultwarden.nix
  ];

  networking.hostName = "leto";

  boot.supportedFilesystems = [ "xfs" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  system.stateVersion = "24.05";
}
