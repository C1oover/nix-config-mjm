{
  pkgs,
  lib,
  config,
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

    # TODO set up wine for xivlauncher
  };
}
