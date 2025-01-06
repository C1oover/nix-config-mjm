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
    mkOption
    optionalString
    types
    ;
  cfg = config.mjm.terminal;
in
{
  options.mjm.terminal.ghostty = {
    enable = mkEnableOption "Ghostty" // {
      default = true;
    };
    fontSize = mkOption {
      type = types.nullOr types.int;
      default = null;
    };
  };

  config = mkIf (cfg.enable && cfg.ghostty.enable) {
    # use cask for ghostty on darwin
    home.packages = mkIf pkgs.stdenv.isLinux [ pkgs.ghostty ];

    xdg.configFile."ghostty/config".text =
      ''
        theme = catppuccin-${config.catppuccin.flavor}
        font-family = PragmataPro Mono Liga
      ''
      + optionalString (cfg.ghostty.fontSize != null) ''
        font-size = ${toString cfg.ghostty.fontSize}
      '';
  };
}
