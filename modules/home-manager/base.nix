{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) attrValues mkDefault;
in
{
  mjm.git.enable = mkDefault true;
  mjm.shell.enable = mkDefault true;

  home.stateVersion = mkDefault "22.11";

  # thanks HM, but I know what I'm doing here.
  # this check always gets weird when a new stable release branches off.
  home.enableNixpkgsReleaseCheck = false;

  home.packages = attrValues {
    inherit (pkgs)
      pstree
      ripgrep
      tree
      unzip
      wget
      ;
  };

  news.display = "silent";
  programs.home-manager.enable = true;
  programs.jq.enable = true;
  xdg.enable = true;

  catppuccin.flavor = osConfig.catppuccin.flavor or "macchiato";
}
