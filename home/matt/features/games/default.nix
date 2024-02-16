{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chiaki
    lutris
    xivlauncher
  ];
}
