{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.desktop;
in
{
  options.mjm.desktop.games = {
    enable = mkEnableOption "games" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.games.enable) {
    home.packages = builtins.attrValues {
      inherit (pkgs) chiaki lutris xivlauncher;
      inherit (pkgs.kdePackages)
        kbreakout
        kmahjongg
        kmines
        kpat
        palapeli
        ;
    };

    home.file.".xlcore/wine-runtimes/proton8-ge".source = inputs.xiv-wine-proton8;
  };
}
