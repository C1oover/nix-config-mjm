{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = [ pkgs.dockutil ];

    targets.darwin.defaults = {
      NSGlobalDomain = {
        AppleFontSmoothing = 0;

        InitialKeyRepeat = 15;
        KeyRepeat = 2;

        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };

      "com.apple.dock" = {
        autohide = true;
        mineffect = "scale";
        mru-spaces = false;
        orientation = "bottom";
        show-recents = false;
        tilesize = 36;

        # disable quick note
        wvous-br-corner = 1;
      };
    };
  };
}
