{ pkgs, lib, ... }:
{
  imports = [
    ../features/firefox
    ../features/kitty
    ../features/newsboat
    ../features/wezterm
    ../features/yubikey
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = lib.mkDefault "matt";
  home.homeDirectory = lib.mkDefault "/Users/matt";

  home.packages = with pkgs; [
    colima
    dockutil

    discord
    shortcat
  ];

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
