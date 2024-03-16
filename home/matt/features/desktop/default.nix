{
  pkgs,
  lib,
  config,
  osConfig,
  inputs,
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
        wl-clipboard
        xclip
        xdg-utils
        zeal
        ;
      inherit (pkgs.callPackages ./scripts.nix { }) night-mode;
      inherit (pkgs.kdePackages) kcalc neochat plasmatube;
      inherit (inputs.plasma-manager.packages.${pkgs.system}) rc2nix;
    };

    programs.mpv.enable = true;

    services.kdeconnect.enable = true;
  };
}
