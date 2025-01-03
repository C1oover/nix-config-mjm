{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./alacritty.nix
    ./ghostty.nix
    ./kitty.nix
    ./wezterm.nix
    ./zellij.nix
  ];

  options.mjm.terminal = {
    enable = mkEnableOption "terminal";
  };
}
