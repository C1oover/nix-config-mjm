{ pkgs, ... }:
{
  imports = [
    ./global

    ./features/bitwarden
    ./features/email
    ./features/helix
    ./features/homelab
    ./features/taskwarrior
  ];

  home.packages = with pkgs; [
    discord
    krita
    yt-dlp

    # needed temporarily while firefox keeps crushing
    chromium
  ];
}
