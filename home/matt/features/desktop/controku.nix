{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.desktop;
in
{
  options.mjm.desktop.controku = {
    enable = mkEnableOption "controku" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.controku.enable) {
    home.packages = with pkgs; [ controku ];

    home.file."${config.xdg.cacheHome}/controku/devices.json".text = builtins.toJSON [
      {
        name = ''55" TCL Roku TV'';
        ip = "10.1.0.111";
      }
    ];
  };
}
