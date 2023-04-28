{ pkgs, ... }:

{
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = "0.0.0.0:8200";
    storageBackend = "consul";
    extraConfig = ''
      ui = true
    '';
  };

  networking.firewall.allowedTCPPorts = [
    8200
    8201
  ];
}
