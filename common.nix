{ config, lib, pkgs, ... }:

{
  imports = [
    lib/neovim.nix
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
    yubikey-agent

    iterm2
    slack

    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  home.file = {};

  xdg.configFile = {
    "starship.toml".source = ./starship.toml;
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.yubikey-agent.sock";
  };

  home.shellAliases = {
    td = "cd $(mktemp -d)";
    hm = "home-manager";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    enableVteIntegration = true;
    defaultKeymap = "emacs";
    initExtra = ''
      if [ -f "$HOME/.asdf/asdf.sh" ]; then . "$HOME/.asdf/asdf.sh"; fi
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

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

  launchd = {
    enable = true;

    agents = {
      "com.mattmoriarity.yubikey-agent" = {
        enable = true;
        config = {
          KeepAlive = true;
          Label = "com.mattmoriarity.yubikey-agent";
          ProgramArguments = ["${pkgs.yubikey-agent}/bin/yubikey-agent" "-l" "${config.home.homeDirectory}/.yubikey-agent.sock"];
          RunAtLoad = true;
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/yubikey-agent.log";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/yubikey-agent.log";
        };
      };
    };
  };

  targets.darwin.defaults = {
    "com.tinyspeck.slackmacgap" = {
      SlackNoAutoUpdates = true;
    };
  };
}
