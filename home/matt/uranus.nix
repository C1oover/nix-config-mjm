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

  mjm.emacs.enable = true;

  home.packages = with pkgs; [
    discord
    krita
    yt-dlp
  ];
}
