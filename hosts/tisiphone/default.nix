{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt
  ];

  networking.hostName = "tisiphone";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  mjm.consul-agent = {
    enable = true;
    server.enable = true;
  };
  mjm.server.enable = true;
  mjm.vault.enable = true;

  system.stateVersion = "22.11";
}
