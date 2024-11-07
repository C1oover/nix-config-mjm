{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib)
    getExe
    mkDefault
    mkIf
    mkEnableOption
    ;
  cfg = config.mjm.terminal;

  nu = osConfig.programs.nushell.wrappedPackage;
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
      catppuccin.enable = true;
      settings = {
        font.normal.family = "Monaspace Xenon";
        font.size = mkDefault 14;
        terminal.shell.program = getExe nu;
        terminal.shell.args = [
          "--login"
          "--interactive"
        ];
        window.option_as_alt = "Both";
      };
    };

    programs.zellij = {
      enable = true;
      catppuccin.enable = true;
    };
  };
}
