{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
  ];

  networking.hostName = "helios";

  boot.supportedFilesystems = [ "xfs" ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  mjm.consul-agent.enable = true;
  mjm.garage.enable = true;

  vault-secrets.roleId = "61d175e1-7a2e-4554-2cca-cff48c926b82";

  system.stateVersion = "22.11";
}
