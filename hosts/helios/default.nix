{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/consul-agent.nix
    ../common/optional/nomad-client.nix
    ../common/optional/nix-remote.nix
  ];

  networking.hostName = "helios";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.consul.interface.advertise = "ens18";

  services.qemuGuest.enable = true;

  system.stateVersion = "22.11";
}
