{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt
  ];

  networking.hostName = "hypnos";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  mjm.consul-agent.enable = true;
  mjm.gitlab-runner.enable = true;
  mjm.server.enable = true;
  mjm.state = {
    enableImpermanence = true;
    persistDir = "/nix/persist";
  };

  vault-secrets.roleId = "70016bfc-5625-b729-f6f2-f08693e12c02";

  system.stateVersion = "22.11";
}
