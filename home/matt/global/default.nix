{
  pkgs,
  lib,
  inputs,
  osConfig,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    "${inputs.agenix}/modules/age-home.nix"
    "${inputs.catppuccin}/modules/home-manager"

    ../features/desktop
    ../features/emacs
    ../features/email
    ../features/firefox
    ../features/git
    ../features/helix
    ../features/homelab
    ../features/shell
    ../features/syncthing
    ../features/terminal
  ] ++ (builtins.attrValues (import ../../../modules/home-manager));

  mjm.git.enable = mkDefault true;
  mjm.shell.enable = mkDefault true;

  home.stateVersion = mkDefault "22.11";

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
  xdg.enable = true;

  catppuccin.flavor = osConfig.catppuccin.flavor or "macchiato";
}
