{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    xdg.configFile.kdeconfig.source = pkgs.linkFarm "kdeconfig" {
      kdeglobals = pkgs.writeText "kdeglobals" ''
        [General]
        AccentColor=146,110,228
        TerminalApplication=ghostty
        TerminalService=com.mitchellh.ghostty.desktop

        [KDE]
        LookAndFeelPackage=org.kde.breezedark.desktop
      '';

      krunnerrc = pkgs.writeText "krunnerrc" ''
        [General]
        FreeFloating=true
      '';

      kwinrc = pkgs.writeText "kwinrc" ''
        [Xwayland]
        Scale=1.25
      '';
    };

    xdg.systemDirs.config = [ "${config.xdg.configHome}/kdeconfig" ];
  };
}
