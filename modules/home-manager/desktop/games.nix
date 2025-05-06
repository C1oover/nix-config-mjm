{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) attrValues mkEnableOption mkIf;
  cfg = config.mjm.desktop;
in
{
  options.mjm.desktop.games = {
    enable = mkEnableOption "games" // {
      default = pkgs.stdenv.isLinux;
    };
  };

  config = mkIf (cfg.enable && cfg.games.enable) {
    home.packages = attrValues {
      inherit (pkgs)
        # build currently broken https://hydra.nixos.org/build/296133688
        # chiaki
        lutris
        wago
        xivlauncher
        ;
      inherit (pkgs.kdePackages)
        kbreakout
        kmahjongg
        kmines
        kpat
        palapeli
        ;
    };

    home.file.".xlcore/wine-runtimes/proton8-ge".source = pkgs.fetchzip {
      url = "https://github.com/rankynbass/wine-ge-xiv/releases/download/xiv-Proton8-26/unofficial-wine-xiv-Proton8-26-x86_64.tar.xz";
      hash = "sha256-lx9AWJutI8iCWA3FbcozxoTOf4zlSdHpdMljwkXUZDA=";
    };

    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture
        obs-mute-filter
        input-overlay
      ];
    };
  };
}
