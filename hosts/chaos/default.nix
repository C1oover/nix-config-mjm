{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/garage.nix

    ./services/jellyfin.nix
    ./services/sabnzbd.nix
    ./services/arr.nix
  ];

  networking.hostName = "chaos";

  boot.supportedFilesystems = ["xfs"];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.qemuGuest.enable = true;

  system.stateVersion = "22.11";
}
