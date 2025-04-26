{ inputs, ... }:
{
  imports = [
    "${inputs.hardware}/framework/13-inch/13th-gen-intel"
    ./hardware-configuration.nix
    ./mounts.nix
    ./secrets.nix
  ];

  # bcachefs has a bug that seems to particularly break go builds
  # this works around that
  boot.tmp.useTmpfs = true;

  networking.hostName = "persephone";

  mjm.desktop.enable = true;
  mjm.desktop.cosmic.enable = true;
  mjm.secureboot.enable = true;
  mjm.state = {
    enablePreservation = true;
    persistDir = "/persist";
    tmpfsRoot = {
      enable = true;
      size = "32G";
    };
    directories = [ "/home" ];
  };

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
