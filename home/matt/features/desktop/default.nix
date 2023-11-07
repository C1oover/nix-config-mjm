{pkgs, ...}: let
  # set brightness and volume for night
  nightMode = pkgs.writeShellApplication {
    name = "night-mode";
    runtimeInputs = with pkgs; [light pulseaudio];
    text = ''
      pactl set-sink-volume @DEFAULT_SINK@ 30%
      light -S 1
    '';
  };
in {
  home.packages = with pkgs; [
    plasma5Packages.kmahjongg
    xdg-utils
    imv
    wl-clipboard
    zeal

    nightMode
  ];

  programs.mpv.enable = true;

  services.kdeconnect.enable = true;
}
