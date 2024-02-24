{ inputs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/ingress
  ];

  networking.hostName = "steropes";

  mjm.consul-agent = {
    enable = true;
    tailscaleIp = "100.103.187.51";
  };
  mjm.nut.enable = true;
  mjm.server.enable = true;

  vault-secrets.roleId = "61445b18-4ebe-027e-7bb9-2c4f6711d408";

  services.tailscale.enable = true;

  boot.initrd.systemd.enableTpm2 = false;

  system.stateVersion = "21.03";
}
