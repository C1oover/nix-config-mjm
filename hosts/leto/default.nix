{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix

    ./services/attic.nix
  ];

  networking.hostName = "leto";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  system.stateVersion = "24.05";
}
