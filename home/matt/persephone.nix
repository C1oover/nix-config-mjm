{pkgs, ...}: {
  imports = [
    ./global

    ./features/controku
    ./features/desktop
    ./features/email
    ./features/firefox
    ./features/games
    ./features/helix
    ./features/homelab
    ./features/kitty
    ./features/newsboat
    ./features/taskwarrior
    ./features/wezterm
  ];

  home.packages = with pkgs; [
    beeper
    discord
  ];
}
