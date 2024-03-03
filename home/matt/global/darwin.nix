{ pkgs, lib, ... }:
{
  imports = [
    ../features/newsboat
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
  mjm.terminal.enable = true;

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
