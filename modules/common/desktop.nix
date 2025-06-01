{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cloover.desktop;
in
{
  options.cloover.desktop = {
    enable = mkEnableOption "desktop environment";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      pragmata-pro
      noto-fonts
    ];
  };
}
