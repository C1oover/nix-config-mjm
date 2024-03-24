{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.wireless;
in
{
  options.mjm.wireless = {
    enable = mkEnableOption "wireless networking";
  };

  config = mkIf cfg.enable {
    networking.networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };
}
