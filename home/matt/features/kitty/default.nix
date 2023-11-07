{pkgs, ...}: let
  fontSize =
    if pkgs.stdenv.isLinux
    then 11
    else 14;
in {
  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    font.name = "Cascadia Code Light";
    font.size = fontSize;
    settings = {
      bold_font = "Cascadia Code";
      italic_font = "Cascadia Code Light Italic";
      bold_italic_font = "Cascadia Code Italic";

      shell = "${pkgs.zsh}/bin/zsh --login --interactive";
      shell_integration = "enabled";
      tab_bar_style = "powerline";
      macos_option_as_alt = "both";
      allow_remote_control = "yes";
      enabled_layouts = "tall:bias=65;full_size=1,fat:bias=70;full_size=1,stack";
      focus_follows_mouse = "yes";
      scrollback_lines = 100000;
    };
    keybindings = {
      "cmd+enter" = "launch --cwd=current";
      "kitty_mod+enter" = "launch --cwd=current";
      "cmd+shift+enter" = "launch --cwd=current --type=tab";
    };
    darwinLaunchOptions = ["--listen-on=unix:kitty.sock"];
  };

  home.packages = with pkgs; [
    (writeShellApplication {
      name = "tt";
      runtimeInputs = [kitty];
      text = ''
        kitty @ set-tab-title "$(basename "$PWD")"
      '';
    })
  ];
}
