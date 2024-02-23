{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/gitlab-runner.nix

    ./impermanence.nix
  ];

  networking.hostName = "hypnos";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  vault-secrets.roleId = "70016bfc-5625-b729-f6f2-f08693e12c02";

  system.stateVersion = "22.11";
}
