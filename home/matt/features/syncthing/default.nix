{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.syncthing;
in
{
  options.mjm.syncthing = {
    enable = mkEnableOption "kitty";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      tray = {
        enable = true;
        package = pkgs.syncthingtray;
        command = "syncthingtray --wait";
      };
    };

    # Workaround for Failed to restart syncthingtray.service: Unit tray.target not found.
    # - https://github.com/nix-community/home-manager/issues/2064
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
