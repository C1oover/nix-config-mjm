{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  mjm.git.enable = mkDefault true;
  mjm.shell.enable = mkDefault true;

  home.stateVersion = mkDefault "22.11";

  # thanks HM, but I know what I'm doing here.
  # this check always gets weird when a new stable release branches off.
  home.enableNixpkgsReleaseCheck = false;

  home.packages = builtins.attrValues (
    {
      inherit (pkgs)
        fx
        gh
        httpie
        hydra-check
        nix-output-monitor
        nix-tree
        pstree
        ripgrep
        serpl
        tree
        unzip
        wget
        ;
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux { inherit (pkgs) attic-client; }
  );

  home.shellAliases = {
    td = "cd $(mktemp -d)";
  };
  programs.nushell.extraConfig = ''
    def --env td [] { cd (mktemp -d) }
  '';

  news.display = "silent";
  programs.home-manager.enable = true;
  programs.jq.enable = true;
  xdg.enable = true;

  catppuccin.flavor = osConfig.catppuccin.flavor or "macchiato";
}
