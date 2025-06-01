{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;
  cfg = config.cloover.secureboot;
in
{
  imports = [
    (import inputs.lanzaboote).nixosModules.lanzaboote
  ];

  options.cloover.secureboot = {
    enable = mkEnableOption "SecureBoot with Lanzaboote";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sbctl ];
    boot.loader.systemd-boot.enable = false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = mkDefault "/etc/secureboot";
    };
    cloover.state.directories = [ config.boot.lanzaboote.pkiBundle ];
  };
}
