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
