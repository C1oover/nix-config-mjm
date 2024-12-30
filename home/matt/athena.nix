{ pkgs, config, ... }:
{
  imports = [ ./global ];

  mjm.aerospace.enable = true;
  mjm.work.enable = true;

  programs.kitty.font.size = 13;
  programs.alacritty.settings.font.size = 16;

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
    { app = "Element"; }
    { app = "Signal"; }
    { app = "Mail"; }
    {
      app = "zoom.us";
      package = pkgs.zoom-us;
    }
    {
      app = "Slack";
      package = pkgs.slack;
    }
    { app = "Fantastical"; }
    { app = "1Password"; }
    { app = "Bitwarden"; }
    { app = "Slab"; }
    {
      app = "kitty";
      package = config.programs.kitty.package;
    }
    {
      app = "Alacritty";
      package = config.programs.alacritty.package;
    }
    { app = "Dash"; }
    { app = "Postico 2"; }
    { app = "Teleport Connect"; }
    { app = "Bruno"; }
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
