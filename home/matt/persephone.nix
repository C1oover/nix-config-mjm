{
  pkgs,
  outputs,
  ...
}: {
  imports = [
    ./global

    ./features/controku
    ./features/desktop
    ./features/email
    ./features/firefox
    ./features/games
    ./features/homelab
    ./features/kitty
    ./features/newsboat
    ./features/taskwarrior
    ./features/wezterm
  ];

  home.packages = with pkgs; [
    discord
    outputs.packages.x86_64-linux.beeper
  ];
}
