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
        cider
        cinny-desktop
        element-desktop
        libreoffice-qt-fresh
        # picard
        sonixd
        strawberry-qt6
        wl-clipboard
        xclip
        xdg-utils
        # won't build currently
        # zeal-qt6
        ;
      inherit (pkgs.callPackages ./scripts.nix { }) night-mode;
      inherit (pkgs.kdePackages)
        kcalc
        ktorrent
        # neochat
        plasmatube
        ;
    };

    programs.mpv.enable = true;

    services.kdeconnect.enable = true;

    fonts.fontconfig.enable = false;
  };
}
