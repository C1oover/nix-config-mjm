{
  pkgs,
  lib,
  inputs,
  osConfig,
  ...
}:
let
  nix-colors = import inputs.nix-colors { };
in
{
  imports = [
    "${inputs.agenix}/modules/age-home.nix"
    nix-colors.homeManagerModules.default
    "${inputs.catppuccin}/modules/home-manager"

    ../features/desktop
    ../features/firefox
    ../features/git
    ../features/shell
    ../features/syncthing
    ../features/terminal
    ../features/xdg
  ] ++ (builtins.attrValues (import ../../../modules/home-manager));

  home.stateVersion = lib.mkDefault "22.11";

  home.packages = builtins.attrValues (
    {
      inherit (pkgs)
        fx
        gh
        httpie
        nix-output-monitor
        nix-tree
        pstree
        ripgrep
        serpl
        tree
        unzip
        wget
        ;

      agenix = pkgs.callPackage "${inputs.agenix}/pkgs/agenix.nix" { };
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

  colorScheme = nix-colors.colorSchemes.catppuccin-macchiato;
  catppuccin.flavor = osConfig.catppuccin.flavor or "macchiato";
}
