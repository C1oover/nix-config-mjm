{ config, ... }:
{
  imports = [ ./global ];

  mjm.terminal.kitty.enable = false;
  mjm.git.enableWatchman = false;

  home.dock.entries = [
    { app = "Messages"; }
    {
      app = "Alacritty";
      package = config.programs.alacritty.package;
    }
  ];
}
