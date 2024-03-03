{ pkgs, lib, ... }:
{
  imports = [
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

  mjm.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
  };

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
