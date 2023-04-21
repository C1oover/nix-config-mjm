{ config, pkgs, ... }:

{
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
    consul
    httpie
    minio-client
    nomad
    pstree
    ripgrep
    tarsnap
    tree
    vault
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

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/matt/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/Users/matt/.yubikey-agent.sock";
  };

  news.display = "silent";

  # Let Home Manager install and manage itself.
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
    delta.enable = true;
    extraConfig = {
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      help.autocorrect = true;
      pull.rebase = false;
      http."https://gitlab.home.mattmoriarity.com".sslCAInfo = builtins.fetchurl "http://vault.service.consul:8200/v1/pki-homelab/ca/pem";
    };
    userName = "Matt Moriarity";
    userEmail = "matt@mattmoriarity.com";
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
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
          ProgramArguments = ["${pkgs.yubikey-agent}/bin/yubikey-agent" "-l" "/Users/matt/.yubikey-agent.sock"];
          RunAtLoad = true;
          StandardErrorPath = "/Users/matt/Library/Logs/yubikey-agent.log";
          StandardOutPath = "/Users/matt/Library/Logs/yubikey-agent.log";
        };
      };
    };
  };
}
