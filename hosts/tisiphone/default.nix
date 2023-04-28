{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/consul-server.nix
    ../common/optional/vault-server.nix
  ];

  networking.hostName = "tisiphone";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  services.consul.extraConfig.retry_join = [ "10.0.2.40" "10.0.2.43" ];

  system.stateVersion = "22.11";
}
