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
  options.mjm.desktop = {
    plasma.enable = mkEnableOption "Plasma desktop environment";
  };

  config = mkIf (cfg.enable && cfg.plasma.enable) {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;

    programs.kdeconnect.enable = true;
    programs.partition-manager.enable = true;
    programs.kde-pim = {
      kmail = true;
      kontact = true;
      merkuro = true;
    };

    environment.systemPackages = [
      pkgs.kdePackages.kdepim-addons
      (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
        [General]
        background=${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/MilkyWay/contents/images/5120x2880.png
      '')
    ];

    # sddm will silently wait 30 sec for a fingerprint after login before timing out
    # i don't want to login with fingerprint anyway (since it wouldn't unlock kwallet)
    security.pam.services.login.fprintAuth = false;
  };
}
