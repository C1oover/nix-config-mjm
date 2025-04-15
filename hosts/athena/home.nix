{ pkgs, config, ... }:
{
  mjm.aerospace.enable = true;
  mjm.work.enable = true;

  mjm.homelab.sshPublicKeyName = "301bb20112f6533610a20ccc216dcbea.pub";
  mjm.terminal.font.size = 15;

  home.packages = builtins.attrValues {
    inherit (pkgs)
      discord
      shortcat
      ;
  };

  home.dock.entries = [
    {
      app = "Firefox";
      package = config.programs.firefox.package;
    }
    "Element"
    "Signal"
    "Mail"
    {
      app = "zoom.us";
      package = pkgs.zoom-us;
    }
    {
      app = "Slack";
      package = pkgs.slack;
    }
    "Fantastical"
    "1Password"
    "Bitwarden"
    "Slab"
    "Ghostty"
    "Dash"
    "Postico 2"
    "Teleport Connect"
    "Bruno"
    {
      path = "${config.home.homeDirectory}/Downloads/";
      section = "others";
      options = "--sort dateadded --view grid --display folder";
    }
  ];

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
