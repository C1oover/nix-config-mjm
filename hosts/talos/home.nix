{
  # We need desktop things here, particularly git credentials and jujutsu, for updating
  # the machine.
  mjm.git.desktop.enable = true;
  mjm.git.enableWatchman = false;

  mjm.terminal.enable = true;
  mjm.terminal.kitty.enable = false;

  home.dock.entries = [
    { app = "Messages"; }
    { app = "Utilities/Terminal"; }
  ];
}
