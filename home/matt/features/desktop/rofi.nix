{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    font = "sans-serif 9";
    terminal = lib.getExe pkgs.kitty;
  };

  home.packages = [
    (pkgs.writeShellApplication {
      name = "rofi-launcher";
      runtimeInputs = [config.programs.rofi.package];
      text = ''
        rofi \
          -show drun \
          -modi run,drun \
          -drun-match-fields all \
          -drun-display-format "{name}" \
          -no-drun-show-actions \
          -theme "${inputs.catppuccin-rofi}/deathemonic/config/launcher.rasi"
      '';
    })
  ];
}
