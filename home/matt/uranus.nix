{ pkgs, ... }:
{
  imports = [
    ./global

    ./features/bitwarden
    ./features/email
    ./features/firefox
    ./features/helix
    ./features/homelab
    ./features/kitty
    ./features/taskwarrior
  ];

  home.packages = with pkgs; [
    beeper
    discord
    krita
    yt-dlp
  ];
}
