{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../features/firefox
    ../features/iterm
    ../features/kitty
    ../features/newsboat
    ../features/yubikey
  ];

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  nixpkgs.config.allowUnfree = true;

  home.username = lib.mkDefault "matt";
  home.homeDirectory = lib.mkDefault "/Users/matt";

  home.packages = with pkgs; [
    dockutil

    discord
    shortcat
    slack
  ];

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
