{ pkgs, lib, outputs, ... }:

{
  imports = [
    ../features/git
    ../features/neovim
    ../features/shell
    ../features/yubikey
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs.config.allowUnfree = true;

  home.username = lib.mkDefault "matt";
  home.homeDirectory = lib.mkDefault "/Users/matt";

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
    dockutil
    httpie
    pstree
    ripgrep
    tree
    wget

    iterm2
    slack
  ];

  home.shellAliases = {
    td = "cd $(mktemp -d)";
    hm = "home-manager";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  programs.jq.enable = true;

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}

