{
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.shell;
in
{
  config = mkIf (cfg.enable && osConfig.programs.zsh.enable) {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      enableVteIntegration = true;
      autosuggestion.enable = true;
      defaultKeymap = "emacs";
      initExtra = ''
        bindkey -- "''${terminfo[kdch1]}" delete-char
      '';
    };

    catppuccin.zsh-syntax-highlighting.enable = true;
  };
}
