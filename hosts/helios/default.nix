{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/consul-agent.nix
    ../common/optional/nomad-client.nix
  ];

  networking.hostName = "helios";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  services.consul.interface.advertise = "ens18";

  services.qemuGuest.enable = true;

  system.stateVersion = "22.11";
}
