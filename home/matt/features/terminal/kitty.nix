{
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;
  cfg = config.mjm.terminal;

  nu = osConfig.programs.nushell.wrappedPackage;
in
{
  options.mjm.terminal.kitty = {
    enable = mkEnableOption "kitty" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.kitty.enable) {
    programs.kitty = {
      enable = true;
      catppuccin.enable = true;
      font.name = "Departure Mono";
      font.size = mkDefault 14;
      settings = {
        # modify_font = "baseline 1";
        shell = "${lib.getExe nu} --login --interactive";
        shell_integration = "enabled";
        tab_bar_style = "powerline";
        macos_option_as_alt = "both";
        allow_remote_control = "yes";
        enabled_layouts = "tall:bias=55;full_size=1,fat:bias=70;full_size=1,stack,splits";
        focus_follows_mouse = "yes";
        scrollback_lines = 100000;
      };
      keybindings = {
        "cmd+enter" = "launch --cwd=current";
        "kitty_mod+enter" = "launch --cwd=current";
        "cmd+shift+enter" = "launch --cwd=current --type=tab";

        "f5" = "launch --cwd=current --location=hsplit";
        "f6" = "launch --cwd=current --location=vsplit";
        "f7" = "layout_action rotate";

        "shift+up" = "move_window up";
        "shift+left" = "move_window left";
        "shift+right" = "move_window right";
        "shift+down" = "move_window down";

        "ctrl+shift+up" = "layout_action move_to_screen_edge top";
        "ctrl+shift+left" = "layout_action move_to_screen_edge left";
        "ctrl+shift+right" = "layout_action move_to_screen_edge right";
        "ctrl+shift+down" = "layout_action move_to_screen_edge bottom";

        "ctrl+up" = "neighboring_window up";
        "ctrl+left" = "neighboring_window left";
        "ctrl+right" = "neighboring_window right";
        "ctrl+down" = "neighboring_window down";
      };
      darwinLaunchOptions = [ "--listen-on=unix:kitty.sock" ];
    };
  };
}
