{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/nix-remote.nix
    ../common/optional/garage
  ];

  networking.hostName = "helios";

  boot.supportedFilesystems = [ "xfs" ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  vault-secrets.roleId = "61d175e1-7a2e-4554-2cca-cff48c926b82";
  vault-secrets.secretIdFile = config.age.secrets."approle-secret-id".path;

  age.secrets."approle-secret-id".file = ../../secrets/helios-approle-secret-id.age;

  system.stateVersion = "22.11";
}
