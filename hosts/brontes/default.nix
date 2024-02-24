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

  networking.hostName = "brontes";

  services.tailscale.enable = true;

  boot.initrd.systemd.enableTpm2 = false;

  mjm.consul-agent = {
    enable = true;
    tailscaleIp = "100.113.14.91";
  };
  mjm.nut.enable = true;
  mjm.server.enable = true;

  vault-secrets.roleId = "3c25aad2-394f-9d07-2885-ebe80f05e9db";

  system.stateVersion = "21.03";
}
