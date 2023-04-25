{ config, lib, pkgs, ... }:

{
  imports = [
    lib/neovim.nix
    lib/shell.nix
    lib/yubikey.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "matt";
  home.homeDirectory = "/Users/matt";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "22.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
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

  programs.git = {
    enable = true;
    aliases = {
      st = "status -sb";
      ci = "commit --verbose";
      di = "diff";
      dc = "diff --cached";
    };
    diff-so-fancy.enable = true;
    extraConfig = {
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      help.autocorrect = 10;
      pull.rebase = false;
      http."https://gitlab.home.mattmoriarity.com".sslCAInfo = builtins.fetchurl "http://vault.service.consul:8200/v1/pki-homelab/ca/pem";
    };
    userName = "Matt Moriarity";
    userEmail = lib.mkDefault "matt@mattmoriarity.com";
  };

  programs.jq.enable = true;

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
