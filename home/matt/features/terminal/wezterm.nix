{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.terminal;
in
{
  options.mjm.terminal.wezterm = {
    enable = mkEnableOption "wezterm";
  };

  config = mkIf (cfg.enable && cfg.wezterm.enable) {
    programs.wezterm = {
      enable = true;
      extraConfig =
        let
          toLua = lib.generators.toLua { };
          vars = {
            font_size = if pkgs.stdenv.isLinux then 8.0 else 14.0;
            colors = builtins.mapAttrs (_name: value: "#${value}") config.colorScheme.palette;
          };
        in
        ''
          local vars = ${toLua vars}

          ${builtins.readFile ./wezterm.lua}
        '';
    };
  };
}
