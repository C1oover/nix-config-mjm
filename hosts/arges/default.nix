{ inputs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt
  ];

  networking.hostName = "arges";

  services.tailscale.enable = true;

  boot.initrd.systemd.enableTpm2 = false;

  mjm.consul-agent = {
    enable = true;
    tailscaleIp = "100.89.174.9";
  };
  mjm.gitlab-runner.enable = true;
  mjm.nut = {
    enable = true;
    mode = "server";
  };
  mjm.server.enable = true;

  vault-secrets.roleId = "841fdaf1-6a2d-f471-ad85-ae485c232b89";

  system.stateVersion = "21.03";
}
