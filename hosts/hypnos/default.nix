{
  imports = [
    ./hardware-configuration.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/gitlab-runner.nix
    ../common/optional/nix-builder.nix

    ./impermanence.nix
  ];

  networking.hostName = "hypnos";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  services.consul.interface.advertise = "ens18";

  system.stateVersion = "22.11";
}
