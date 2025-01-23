{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  cfg = config.mjm.terminal;
in
{
  options.mjm.terminal.ghostty = {
    enable = mkEnableOption "Ghostty" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.ghostty.enable) {
    # use cask for ghostty on darwin
    home.packages = mkIf pkgs.stdenv.isLinux [ pkgs.ghostty ];

    xdg.configFile."ghostty/config".text = ''
      theme = catppuccin-${config.catppuccin.flavor}
      font-family = ${cfg.font.family}
      font-size = ${toString cfg.font.size}
    '';
  };
}
