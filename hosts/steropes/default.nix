{inputs, ...}: {
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/consul-agent.nix
    ../common/optional/nomad-client.nix
    ../common/optional/nix-remote.nix
  ];

  networking.hostName = "steropes";

  services.consul.interface.advertise = "end0";

  system.stateVersion = "21.03";
}
