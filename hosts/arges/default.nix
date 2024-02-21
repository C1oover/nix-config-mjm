{ config, inputs, ... }:
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

    ./services/nut-server.nix
  ];

  networking.hostName = "arges";

  services.consul.extraConfig.node_meta.tailscale_ip = "100.89.174.9";

  services.tailscale.enable = true;

  boot.initrd.systemd.enableTpm2 = false;

  vault-secrets.roleId = "841fdaf1-6a2d-f471-ad85-ae485c232b89";
  vault-secrets.secretIdFile = config.age.secrets.approle-secret-id.path;

  age.secrets.approle-secret-id.file = ../../secrets/arges-approle-secret-id.age;

  system.stateVersion = "21.03";
}
