{
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.mjm.shell;
in
{
  imports = [
    ./fish.nix
    ./nushell.nix
    ./starship.nix
    ./zsh.nix
  ];

  options.mjm.shell = {
    enable = mkEnableOption "shell config";
    desktop.enable = mkEnableOption "tools only needed on workstations";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.atuin = {
        enable = true;
        daemon.enable = true;
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

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;

        config = {
          global.warn_timeout = "1m";
        };
      };

      programs.bat.enable = true;
      programs.btop.enable = true;
      programs.carapace.enable = true;
      programs.dircolors.enable = true;
      programs.zoxide.enable = true;

      catppuccin = {
        bat.enable = true;
        btop.enable = true;
      };
    }

    (mkIf cfg.desktop.enable {
      programs.fzf.enable = true;
      programs.yazi.enable = true;

      catppuccin = {
        fzf.enable = true;
        yazi.enable = true;
      };

      xdg.configFile."process-compose/theme.yaml".source =
        "${inputs.catppuccin-process-compose}/themes/catppuccin-${config.catppuccin.flavor}.yaml";
    })
  ]);
}
