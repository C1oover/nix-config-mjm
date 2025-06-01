{ lib, config, ... }:
let
  inherit (lib) mkDefault mkEnableOption mkIf;
  cfg = config.cloover.userborn;
in
{
  options.cloover.userborn = {
    enable = mkEnableOption "userborn" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    system.etc.overlay.enable = mkDefault true;

    services.userborn = {
      enable = true;
      passwordFilesLocation = "/var/lib/nixos";
    };
  };
}
