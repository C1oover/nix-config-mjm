{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-server.nix
    ../common/optional/vault-server.nix
    ../common/optional/nomad-server.nix
    ../common/optional/nix-remote.nix
  ];

  networking.hostName = "tisiphone";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    storePath = "/persist/nix/store";
  };

  services.qemuGuest.enable = true;

  system.stateVersion = "22.11";
}
