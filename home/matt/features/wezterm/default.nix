{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.wezterm = {
    enable = true;
    extraConfig = let
      toLua = lib.generators.toLua {};
      vars = {
        font_size =
          if pkgs.stdenv.isLinux
          then 8.0
          else 14.0;
        colors = builtins.mapAttrs (_name: value: "#${value}") config.colorScheme.colors;
      };
    in ''
      local vars = ${toLua vars}

      ${builtins.readFile ./wezterm.lua}
    '';
  };
}
