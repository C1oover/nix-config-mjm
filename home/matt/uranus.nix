{ pkgs, ... }:
{
  imports = [
    ./global

    ./features/bitwarden
    ./features/homelab
    ./features/taskwarrior
  ];

  mjm.emacs.enable = true;
  mjm.email.enable = true;
  mjm.helix.enable = true;

  home.packages = with pkgs; [
    discord
    krita
    yt-dlp
  ];
}
