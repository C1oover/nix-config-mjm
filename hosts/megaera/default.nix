{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/consul-server.nix
    ../common/optional/vault-server.nix
    ../common/optional/nomad-server.nix
  ];

  networking.hostName = "megaera";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  system.stateVersion = "22.11";
}
