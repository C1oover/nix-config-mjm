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
      default = pkgs.stdenv.isLinux;
    };
  };

  config = mkIf (cfg.enable && cfg.ghostty.enable) {
    home.packages = [ pkgs.ghostty ];

    xdg.configFile."ghostty/config".text = ''
      theme = catppuccin-${config.catppuccin.flavor}
      font-family = PragmataPro Mono Liga
    '';
  };
}
