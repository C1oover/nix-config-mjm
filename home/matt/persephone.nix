{ pkgs, ... }:
{
  imports = [
    ./global

    ./features/bitwarden
    ./features/email
    ./features/homelab
    ./features/taskwarrior
  ];

  mjm.emacs.enable = true;
  mjm.helix.enable = true;

  home.packages = with pkgs; [
    discord
    krita
    yt-dlp
  ];

  programs.kitty.font.size = 15;
}
