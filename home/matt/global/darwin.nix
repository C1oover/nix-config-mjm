{ pkgs
, lib
, inputs
, ...
}: {
  imports = [
    ../features/yubikey
    ../features/iterm
    ../features/kitty
  ];

  nixpkgs.overlays = [ inputs.nixpkgs-firefox-darwin.overlay ];
  nixpkgs.config.allowUnfree = true;

  home.username = lib.mkDefault "matt";
  home.homeDirectory = lib.mkDefault "/Users/matt";

  home.packages = with pkgs; [
    dockutil

    discord
    firefox-bin
    slack
  ];

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
