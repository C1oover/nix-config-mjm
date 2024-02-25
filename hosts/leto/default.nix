{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ./services/actual.nix
    ./services/attic.nix
    ./services/atuin.nix
    ./services/authelia
    ./services/grafana.nix
    ./services/homelab.nix
    ./services/home-assistant.nix
    ./services/linkding.nix
    ./services/lldap.nix
    ./services/loki.nix
    ./services/miniflux.nix
    ./services/netbox.nix
    ./services/paperless.nix
    ./services/postgresql.nix
    ./services/prometheus
    ./services/taskserver.nix
    ./services/tempo.nix
    ./services/vaultwarden.nix
  ];

  networking.hostName = "leto";

  boot.supportedFilesystems = [ "xfs" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  mjm.consul-agent.enable = true;
  mjm.garage.enable = true;
  mjm.server.enable = true;

  vault-secrets.roleId = "29829ea8-3eb2-b3d6-8aab-d150dbb48e3d";

  system.stateVersion = "24.05";
}
