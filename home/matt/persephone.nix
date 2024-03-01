{ pkgs, ... }:
{
  imports = [
    ./global

    ./features/bitwarden
    ./features/controku
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
    krita
    yt-dlp
  ];
}
