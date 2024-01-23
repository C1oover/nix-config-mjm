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
    ../common/optional/gitlab-runner.nix
    ../common/optional/nix-builder.nix

    ./services/nut-server.nix
  ];

  networking.hostName = "arges";

  services.consul.extraConfig.node_meta.tailscale_ip = "100.89.174.9";

  services.tailscale.enable = true;

  system.stateVersion = "21.03";
}
