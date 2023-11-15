{
  pkgs,
  inputs,
  ...
}: let
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
  imports = [
    ./rc.nix
  ];

  home.packages = builtins.attrValues {
    inherit nightMode;
    inherit (pkgs) imv wl-clipboard xdg-utils zeal;
    inherit (pkgs.plasma5Packages) kbreakout kmahjongg kmines palapeli;
    inherit (inputs.plasma-manager.packages.${pkgs.system}) rc2nix;
  };

  programs.mpv.enable = true;

  services.kdeconnect.enable = true;
}
