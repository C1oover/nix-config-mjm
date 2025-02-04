{ config, ... }:
{
  mjm.terminal.enable = true;

  home.dock.entries = [
    { app = "Messages"; }
    {
      app = "Alacritty";
      package = config.programs.alacritty.package;
    }
  ];
}
