{ pkgs
, lib
, ...
}: {
  imports = [
    ../features/yubikey
    ../features/iterm
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = lib.mkDefault "matt";
  home.homeDirectory = lib.mkDefault "/Users/matt";

  home.packages = with pkgs; [
    dockutil

    discord
    slack
  ];

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
