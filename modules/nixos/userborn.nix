{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.userborn;
in
{
  options.mjm.userborn = {
    enable = mkEnableOption "userborn" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    system.etc.overlay.enable = true;
    services.userborn = {
      enable = true;
      passwordFilesLocation = "/var/lib/nixos";
    };
  };
}
