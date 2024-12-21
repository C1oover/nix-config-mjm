{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.work;
in
{
  config = mkIf cfg.enable {
    programs.k9s.enable = true;
    catppuccin.k9s.enable = true;

    programs.nushell.extraConfig = ''
      def --wrapped k9s [...args] {
        do {
          hide-env SSH_AUTH_SOCK
          ^k9s ...$args
        }
      }
    '';
  };
}
