{inputs, ...}: {
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/nomad-client.nix
    ../common/optional/nix-builder.nix
  ];

  networking.hostName = "arges";

  services.consul.interface.advertise = "end0";

  services.tailscale.enable = true;

  system.stateVersion = "21.03";
}
