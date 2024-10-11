{
  imports = [
    ./global

    ./features/taskwarrior
  ];

  programs.kitty.font.size = 15;

  mjm.homelab.enableYubikey = false;
}
