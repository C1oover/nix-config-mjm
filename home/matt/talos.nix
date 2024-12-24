{ config, ... }:
{
  imports = [
    ./global
    ./global/darwin.nix
  ];

  # mjm.helix.enable = true;
  mjm.terminal.kitty.enable = false;
  mjm.git.enableWatchman = false;

  home.dock.entries = [
    {
      app = "Firefox";
      package = config.programs.firefox.package;
    }
    { app = "Messages"; }
    {
      app = "Alacritty";
      package = config.programs.alacritty.package;
    }
  ];
}
