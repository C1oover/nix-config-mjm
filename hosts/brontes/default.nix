{ inputs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/nut-client.nix
    ../common/optional/ingress
  ];

  networking.hostName = "brontes";

  services.tailscale.enable = true;

  boot.initrd.systemd.enableTpm2 = false;

  mjm.consul-agent = {
    enable = true;
    tailscaleIp = "100.113.14.91";
  };
  mjm.server.enable = true;

  system.stateVersion = "21.03";
}
