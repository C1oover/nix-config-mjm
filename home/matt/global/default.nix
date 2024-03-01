{
  pkgs,
  lib,
  outputs,
  inputs,
  ...
}:
{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.nix-colors.homeManagerModules.default

    ../features/git
    ../features/shell
    ../features/xdg

    ../features/desktop
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  home.stateVersion = lib.mkDefault "22.11";

  home.packages = builtins.attrValues (
    {
      inherit (pkgs)
        btop
        fx
        gh
        httpie
        nix-output-monitor
        nix-tree
        pstree
        ripgrep
        tree
        unzip
        wget
        ;

      inherit (inputs.home-manager.packages.${pkgs.system}) home-manager;
      agenix = inputs.agenix.packages.${pkgs.system}.default;
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux { inherit (pkgs) attic-client; }
  );

  home.shellAliases = {
    td = "cd $(mktemp -d)";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  programs.jq.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;
}
