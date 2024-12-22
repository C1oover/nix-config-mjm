{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dockutil
  ];

  mjm.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
  };
  mjm.terminal.enable = true;
}
