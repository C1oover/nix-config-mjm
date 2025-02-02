{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;
  cfg = config.mjm.secureboot;
in
{
  imports = [
    (import inputs.lanzaboote).nixosModules.lanzaboote
  ];

  options.mjm.secureboot = {
    enable = mkEnableOption "SecureBoot with Lanzaboote";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sbctl ];
    boot.loader.systemd-boot.enable = false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = mkDefault "/etc/secureboot";
    };
    mjm.state.directories = [ config.boot.lanzaboote.pkiBundle ];
  };
}
