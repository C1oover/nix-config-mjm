{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
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

    font = {
      family = mkOption {
        type = types.str;
        default = "PragmataPro Mono Liga";
      };
      size = mkOption {
        type = types.int;
        default = 10;
      };
    };
  };
}
