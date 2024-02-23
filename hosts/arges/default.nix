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
    ../common/optional/gitlab-runner.nix

    ./services/nut-server.nix
  ];

  networking.hostName = "arges";

  services.tailscale.enable = true;

  boot.initrd.systemd.enableTpm2 = false;

  mjm.consul-agent = {
    enable = true;
    tailscaleIp = "100.89.174.9";
  };

  vault-secrets.roleId = "841fdaf1-6a2d-f471-ad85-ae485c232b89";

  system.stateVersion = "21.03";
}
