{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    attrValues
    mkEnableOption
    mkIf
    optionals
    ;
  cfg = config.mjm.desktop;
in
{
  options.mjm.desktop.games = {
    enable = mkEnableOption "games" // {
      default = pkgs.stdenv.isLinux;
    };
  };

  config = mkIf (cfg.enable && cfg.games.enable) {
    home.packages =
      attrValues {
        inherit (pkgs)
          chiaki
          ;
        inherit (pkgs.kdePackages)
          kbreakout
          kmahjongg
          kmines
          kpat
          palapeli
          ;
      }
      ++ optionals pkgs.stdenv.isx86_64 [
        pkgs.lutris
        pkgs.wago
        pkgs.xivlauncher
      ];

    home.file.".xlcore/wine-runtimes/proton8-ge".source = pkgs.fetchzip {
      url = "https://github.com/rankynbass/wine-ge-xiv/releases/download/xiv-Proton8-26/unofficial-wine-xiv-Proton8-26-x86_64.tar.xz";
      hash = "sha256-lx9AWJutI8iCWA3FbcozxoTOf4zlSdHpdMljwkXUZDA=";
    };

    programs.obs-studio = {
      enable = pkgs.stdenv.isx86_64;
      plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture
        obs-mute-filter
        input-overlay
      ];
    };
  };
}
