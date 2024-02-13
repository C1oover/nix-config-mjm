{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lutris
    xivlauncher
  ];
}
