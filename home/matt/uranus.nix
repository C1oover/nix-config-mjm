{ pkgs, ... }:
{
  imports = [
    ./global

    ./features/bitwarden
    ./features/homelab
    ./features/taskwarrior
  ];

  home.packages = with pkgs; [
    discord
    krita
    yt-dlp
  ];
}
