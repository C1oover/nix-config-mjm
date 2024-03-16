{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt
  ];

  networking.hostName = "helios";

  boot.supportedFilesystems = [ "xfs" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  mjm.consul-agent.enable = true;
  mjm.garage.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "61d175e1-7a2e-4554-2cca-cff48c926b82";

  system.stateVersion = "22.11";
}
