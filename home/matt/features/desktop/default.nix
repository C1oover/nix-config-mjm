{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.mjm.desktop;
in
{
  imports = [
    ./controku.nix
    ./firefox.nix
    ./games.nix
    ./kdeconfig.nix
    ./syncthing.nix
    ./terminal.nix
  ];

  options.mjm.desktop = {
    enable = mkOption {
      type = types.bool;
      default = osConfig.mjm.desktop.enable or false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = builtins.attrValues {
      inherit (pkgs)
        bitwarden
        element-desktop
        libreoffice-qt-fresh
        piper
        signal-desktop
        strawberry-qt6
        wl-clipboard
        xclip
        xdg-utils
        # won't build currently
        # zeal-qt6
        ;
      inherit (pkgs.callPackages ./scripts.nix { }) night-mode;
      inherit (pkgs.kdePackages)
        filelight
        kcalc
        ktorrent
        plasmatube
        ;
    };

    programs.mpv.enable = true;

    services.kdeconnect.enable = true;

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
