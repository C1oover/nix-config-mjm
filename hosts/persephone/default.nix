{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    "${inputs.hardware}/framework/13-inch/13th-gen-intel"
    ./hardware-configuration.nix
    ./mounts.nix
    ./secrets.nix
  ];

  mjm.desktop.enable = true;
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

  environment.systemPackages = [
    pkgs.unofficial-homestuck-collection
  ];

  networking.hostName = "persephone";

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  services.openssh.enable = true;

  system.stateVersion = "23.05";
}
