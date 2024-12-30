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

      # not sure if this one is safe, particularly with the indices for Containments
      # plasma-org.kde.plasma.desktop-appletsrc = pkgs.writeText "appletsrc" ''
      #   [Containments][1][Wallpaper][org.kde.image][General]
      #   Image=/run/current-system/sw/share/wallpapers/MilkyWay/
      #   PreviewImage=/run/current-system/sw/share/wallpapers/MilkyWay/

      #   [Containments][2][Wallpaper][org.kde.image][General]
      #   Image=/run/current-system/sw/share/wallpapers/MilkyWay/
      #   PreviewImage=/run/current-system/sw/share/wallpapers/MilkyWay/
      # '';

      kscreenlockerrc = pkgs.writeText "kscreenlockerrc" ''
        [Greeter][Wallpaper][org.kde.image][General]
        Image=/run/current-system/sw/share/wallpapers/MilkyWay/
        PreviewImage=/run/current-system/sw/share/wallpapers/MilkyWay/
      '';
    };

    xdg.systemDirs.config = [ "${config.xdg.configHome}/kdeconfig" ];
  };
}
