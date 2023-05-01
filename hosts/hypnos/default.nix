{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos.nix
    ../common/users/matt

    ../common/optional/consul-agent.nix
    ../common/optional/gitlab-runner.nix
  ];

  networking.hostName = "hypnos";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  services.consul.interface.advertise = "ens18";

  system.stateVersion = "22.11";
}
