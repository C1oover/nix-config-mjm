{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.mjm.terminal;
in
{
  options.mjm.terminal.alacritty = {
    enable = mkEnableOption "alacritty" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.alacritty.enable) {
    programs.alacritty = {
      enable = true;
      settings = {
        font.normal.family = cfg.font.family;
        font.size = cfg.font.size;
        window.option_as_alt = "Both";
      };
    };

    catppuccin.alacritty.enable = true;
  };
}
