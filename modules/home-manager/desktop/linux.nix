{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) attrValues mkDefault mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    mjm.emacs.enable = mkDefault true;
    mjm.email.enable = mkDefault true;
    mjm.homelab.enable = mkDefault true;
    mjm.syncthing.enable = mkDefault true;

    home.packages = attrValues {
      inherit (pkgs)
        bitwarden
        element-desktop
        discord
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

    services.easyeffects.enable = true;

    fonts.fontconfig.enable = false;

    # Noto Sans Mono doesn't have a spacing value set, so kitty won't allow its
    # use on Linux without forcing the issue.
    xdg.configFile."fontconfig/conf.d/50-noto-mono.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
      <match target="scan">
          <test name="family">
              <string>Noto Sans Mono</string>
          </test>
          <edit name="spacing">
              <int>100</int>
          </edit>
      </match>
      </fontconfig>
    '';
  };
}
