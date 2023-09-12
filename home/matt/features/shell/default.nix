{
  pkgs,
  inputs,
  ...
}: {
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;
    defaultKeymap = "emacs";
    initExtra = ''
      if [ -f "$HOME/.asdf/asdf.sh" ]; then . "$HOME/.asdf/asdf.sh"; fi
      source ${inputs.catppuccin-zsh + /themes/catppuccin_mocha-zsh-syntax-highlighting.zsh}
      bindkey -- "''${terminfo[kdch1]}" delete-char
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."starship.toml".text = ''
    format = "$all"
    palette = "catppuccin_mocha"
    command_timeout = 2000

    [os]
    disabled = false

    [gcloud]
    disabled = true

    [docker_context]
    disabled = true

    ${builtins.readFile ./nerd-font-symbols.toml}
    ${builtins.readFile (inputs.catppuccin + /palettes/mocha.toml)}
  '';

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
    colors = {
      "bg+" = "#313244";
      bg = "#1e1e2e";
      spinner = "#f5e0dc";
      hl = "#f38ba8";
      fg = "#cdd6f4";
      header = "#f38ba8";
      info = "#cba6f7";
      pointer = "#f5e0dc";
      marker = "#f5e0dc";
      "fg+" = "#cdd6f4";
      prompt = "#cba6f7";
      "hl+" = "#f38ba8";
    };
  };

  programs.atuin = {
    enable = true;
    settings = {
      sync_address = "https://atuin.home.mattmoriarity.com";
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
    enableAliases = true;
    git = true;
    icons = true;
  };

  programs.bat = {
    enable = true;
    themes.Catppuccin-mocha = builtins.readFile "${inputs.catppuccin-bat}/Catppuccin-mocha.tmTheme";
    config.theme = "Catppuccin-mocha";
  };
}
