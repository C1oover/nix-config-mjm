{ pkgs, ... }:
{
  imports = [
    ./global

    ./features/bitwarden
    ./features/email
    ./features/helix
    ./features/homelab
    ./features/newsboat
    ./features/taskwarrior
  ];

  home.packages = with pkgs; [
    beeper
    discord
    krita
    yt-dlp
  ];
}
