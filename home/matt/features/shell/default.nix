{
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib) mkMerge;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
      catppuccin.enable = true;
    };
    enableVteIntegration = true;
    autosuggestion.enable = true;
    defaultKeymap = "emacs";
    initExtra = ''
      if [ -f "$HOME/.asdf/asdf.sh" ]; then . "$HOME/.asdf/asdf.sh"; fi
      bindkey -- "''${terminfo[kdch1]}" delete-char
    '';
  };

  programs.nushell = {
    enable = true;
    extraConfig = ''
      $env.config.show_banner = false
      $env.config.shell_integration = {
        osc2: true
        osc7: true
        osc8: true
        osc9_9: false
        osc133: true
        osc633: true
        reset_application_mode: true
      }
    '';
  };

  programs.starship = {
    enable = true;
    catppuccin.enable = true;
    settings = mkMerge [
      {
        command_timeout = 2000;
        os.disabled = true;
        gcloud.disabled = true;
        docker_context.disabled = true;
      }
      (builtins.fromTOML (builtins.readFile ./nerd-font-symbols.toml))
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;

    config = {
      global.warn_timeout = "1m";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    catppuccin.enable = true;
  };

  programs.atuin = {
    enable = true;
    settings = {
      sync_address = "https://atuin.midna.dev";
    };
  };

  programs.dircolors.enable = true;
  programs.zoxide.enable = true;

  programs.eza = {
    enable = true;
    # enableNushellIntegration = true;
    git = true;
    icons = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--smart-group"
      "--group"
    ];
  };

  programs.bat = {
    enable = true;
    catppuccin.enable = true;
  };

  programs.yazi = {
    enable = true;
    catppuccin.enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  programs.btop = {
    enable = true;
    catppuccin.enable = true;
  };

  xdg.configFile."process-compose/theme.yaml".source = "${inputs.catppuccin-process-compose}/themes/catppuccin-${config.catppuccin.flavor}.yaml";
}
