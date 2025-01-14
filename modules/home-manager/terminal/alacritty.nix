{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    mkEnableOption
    ;
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
        font.normal.family = "PragmataPro Mono Liga";
        font.size = mkDefault 14;
        window.option_as_alt = "Both";
      };
    };

    catppuccin.alacritty.enable = true;
  };
}
