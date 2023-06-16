{pkgs, ...}: {
  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    font.name = "PragmataPro Mono";
    font.size = 16;
    settings = {
      shell = "${pkgs.nushell}/bin/nu --login --interactive";
      shell_integration = "enabled";
      tab_bar_style = "powerline";
      macos_option_as_alt = "both";
      allow_remote_control = "yes";
      enabled_layouts = "tall:bias=65;full_size=1,fat:bias=70;full_size=1,stack";
    };
    keybindings = {
      "cmd+enter" = "launch --cwd=current";
      "kitty_mod+enter" = "launch --cwd=current";
      "cmd+shift+enter" = "launch --cwd=current --type=tab";
    };
    darwinLaunchOptions = ["--listen-on=unix:kitty.sock"];
  };
}
