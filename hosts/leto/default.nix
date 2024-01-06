{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix

    ./services/actual.nix
    ./services/attic.nix
    ./services/netbox.nix
    ./services/paperless.nix
  ];

  networking.hostName = "leto";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  system.stateVersion = "24.05";
}
