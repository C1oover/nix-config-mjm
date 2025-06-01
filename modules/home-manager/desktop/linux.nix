{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) attrValues mkDefault mkIf;
  cfg = config.cloover.desktop;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # cloover.emacs.enable = mkDefault true;
    cloover.email.enable = mkDefault true;
    cloover.syncthing.enable = mkDefault true;

    home.packages = attrValues {
      inherit (pkgs)
        bitwarden
        element-desktop
        krita
        libreoffice-qt-fresh
        piper
        signal-desktop
        strawberry-qt6
        unofficial-homestuck-collection
        wl-clipboard
        xclip
        xdg-utils
        yt-dlp
        zeal-qt6
        ;
      inherit (pkgs.kdePackages)
        filelight
        kcalc
        ktorrent
        plasmatube
        ;
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;

      desktop = "${config.home.homeDirectory}/desktop";
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      music = null;
      pictures = "${config.home.homeDirectory}/pictures";
      publicShare = null;
      templates = null;
      videos = null;
    };

    programs.mpv.enable = true;

    services.kdeconnect.enable = true;

    # don't really need this right now if I'm using the amp, and it seems to
    # block shutdown for a solid minute and a half.
    #
    # services.easyeffects.enable = true;

    fonts.fontconfig.enable = false;
  };
}
