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
  imports = [
    ./alacritty.nix
    ./kitty.nix
    ./wezterm.nix
  ];

  options.mjm.terminal = {
    enable = mkEnableOption "terminal";
  };

  config = mkIf cfg.enable {
    home.packages = builtins.attrValues { inherit (pkgs.callPackages ./scripts.nix { }) tt; };
  };
}
