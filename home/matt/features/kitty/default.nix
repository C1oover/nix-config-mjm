{ pkgs, ... }:
let
  fontSize = if pkgs.stdenv.isLinux then 12 else 14;
in
{
  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    font.name = "Agave";
    font.size = fontSize;
    settings = {
      shell = "${pkgs.zsh}/bin/zsh --login --interactive";
      shell_integration = "enabled";
      tab_bar_style = "powerline";
      macos_option_as_alt = "both";
      allow_remote_control = "yes";
      enabled_layouts = "tall:bias=55;full_size=1,fat:bias=60;full_size=1,stack";
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

  home.packages = builtins.attrValues { inherit (pkgs.callPackages ./scripts.nix { }) tt; };
}
