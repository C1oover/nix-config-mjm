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
    discord
    krita
    yt-dlp
  ];

  programs.kitty.font.size = 15;
}
