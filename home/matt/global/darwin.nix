{ pkgs, lib, outputs, ... }:

{
  imports = [
    ../features/yubikey
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = lib.mkDefault "matt";
  home.homeDirectory = lib.mkDefault "/Users/matt";

  home.packages = with pkgs; [
    dockutil

    iterm2
    slack
  ];

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}


