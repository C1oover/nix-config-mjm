{ inputs, lib, ... }:
let
  inherit (lib) mkMerge;
in
{
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;
    autosuggestion.enable = true;
    defaultKeymap = "emacs";
    initExtra = ''
      if [ -f "$HOME/.asdf/asdf.sh" ]; then . "$HOME/.asdf/asdf.sh"; fi
      source ${
        inputs.catppuccin-zsh-syntax-highlighting + /themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
      }
      bindkey -- "''${terminfo[kdch1]}" delete-char
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
    enableZshIntegration = true;
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

  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
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
  };

  programs.btop = {
    enable = true;
    catppuccin.enable = true;
  };
}
