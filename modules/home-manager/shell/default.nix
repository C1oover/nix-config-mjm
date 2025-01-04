{
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib)
    importTOML
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    ;
  cfg = config.mjm.shell;
in
{
  options.mjm.shell = {
    enable = mkEnableOption "shell config";
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
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

        def --env td [] {
          cd (mktemp -d)
        }

        def without-cache [block] {
          with-env { NIX_CONFIG: "substituters = https://cache.nixos.org" } $block
        }
      '';
    };

    programs.starship = {
      enable = true;
      settings = mkMerge [
        {
          command_timeout = 2000;
          os.disabled = true;
          gcloud.disabled = true;
          docker_context.disabled = true;
          terraform.disabled = true;
          git_metrics.disabled = mkForce true;
          sudo.disabled = mkForce true;
          nix_shell.heuristic = true;

          format = mkForce "($nix_shell$container\${custom.jj}\${custom.jj_added}\${custom.jj_removed}\n)$cmd_duration$hostname$localip$shlvl$shell$env_var$jobs$sudo$username$character";
        }
        (importTOML ./jetpack.toml)
        # (builtins.fromTOML (builtins.readFile ./nerd-font-symbols.toml))
      ];
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;

      config = {
        global.warn_timeout = "1m";
      };
    };

    programs.atuin = {
      enable = true;
      settings = {
        sync_address = "https://atuin.midna.dev";
      };
    };

    programs.eza = {
      enable = true;
      git = true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
        "--header"
        "--smart-group"
        "--group"
      ];
    };

    programs.bat.enable = true;
    programs.btop.enable = true;
    programs.carapace.enable = true;
    programs.dircolors.enable = true;
    programs.fzf.enable = true;
    programs.yazi.enable = true;
    programs.zoxide.enable = true;

    catppuccin = {
      bat.enable = true;
      btop.enable = true;
      fzf.enable = true;
      starship.enable = true;
      yazi.enable = true;
      zsh-syntax-highlighting.enable = true;
    };

    xdg.configFile."process-compose/theme.yaml".source =
      "${inputs.catppuccin-process-compose}/themes/catppuccin-${config.catppuccin.flavor}.yaml";
  };
}
