{ inputs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/nomad-client.nix
    ../common/optional/nix-remote.nix
    ../common/optional/nut-client.nix
    ../common/optional/ingress
  ];

  networking.hostName = "brontes";

  services.consul.extraConfig.node_meta.tailscale_ip = "100.113.14.91";

  services.tailscale.enable = true;

  system.stateVersion = "21.03";
}
