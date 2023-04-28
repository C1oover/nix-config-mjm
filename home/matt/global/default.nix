{ pkgs, lib, outputs, ... }:

{
  imports = [
    ../features/git
    ../features/neovim
    ../features/shell
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = lib.mkDefault "22.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    colima
    httpie
    pstree
    ripgrep
    tree
    wget
  ];

  home.shellAliases = {
    td = "cd $(mktemp -d)";
    hm = "home-manager";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  programs.jq.enable = true;
}

