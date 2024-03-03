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
  config = mkIf cfg.enable {
    xdg.configFile.kdeconfig.source = pkgs.linkFarm "kdeconfig" {
      kdeglobals = pkgs.writeText "kdeglobals" ''
        [General]
        AccentColor=146,110,228
        TerminalApplication=kitty
        TerminalService=kitty.desktop

        [KDE]
        LookAndFeelPackage=org.kde.breezedark.desktop
      '';

      kglobalshortcutsrc = pkgs.writeText "kglobalshortcutsrc" ''
        [services][org.kde.krunner.desktop]
        _launch=Alt+F2\tMeta+Space\tSearch
      '';

      krunnerrc = pkgs.writeText "krunnerrc" ''
        [General]
        FreeFloating=true
      '';

      kwinrc = pkgs.writeText "kwinrc" ''
        [Windows]
        FocusPolicy=FocusFollowsMouse

        [Xwayland]
        Scale=1.25
      '';
    };

    xdg.systemDirs.config = [ "${config.xdg.configHome}/kdeconfig" ];
  };
}
