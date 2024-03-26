{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkEnableOption mkIf;
  cfg = config.mjm.terminal;

  fontSize = if pkgs.stdenv.isLinux then 12 else 14;
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
      theme = "Catppuccin-Macchiato";
      font.name = "Agave";
      font.size = mkDefault fontSize;
      settings = {
        shell = "${pkgs.zsh}/bin/zsh --login --interactive";
        shell_integration = "enabled";
        tab_bar_style = "powerline";
        macos_option_as_alt = "both";
        allow_remote_control = "yes";
        enabled_layouts = "tall:bias=55;full_size=1,fat:bias=70;full_size=1,stack";
        focus_follows_mouse = "yes";
        scrollback_lines = 100000;
      };
      keybindings = {
        "cmd+enter" = "launch --cwd=current";
        "kitty_mod+enter" = "launch --cwd=current";
        "cmd+shift+enter" = "launch --cwd=current --type=tab";
      };
      darwinLaunchOptions = [ "--listen-on=unix:kitty.sock" ];
    };
  };
}
