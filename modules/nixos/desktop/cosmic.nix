{
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
    cosmic = {
      enable = mkEnableOption "COSMIC desktop environment";
    };
  };

  config = mkIf (cfg.enable && cfg.cosmic.enable) {
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.enable = true;

    # want to login with password so it unlocks the keyring
    security.pam.services.login.fprintAuth = false;
    security.pam.services.cosmic-greeter.fprintAuth = false;
    security.pam.services.greetd.fprintAuth = false;
    security.pam.services.cosmic-greeter.enableGnomeKeyring = true;
    security.pam.services.greetd.enableGnomeKeyring = true;

    programs.gnupg.agent.enable = true;
    programs.seahorse.enable = true;
  };
}
