{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.terminal;
in
{
  options.mjm.terminal.zellij = {
    enable = mkEnableOption "zellij" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.zellij.enable) {
    programs.zellij = {
      enable = true;
    };

    xdg.configFile."zellij/config.kdl".source = pkgs.substituteAll {
      src = ./zellij.kdl;
      copy_command = if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy";
    };

    programs.fish.functions.",tt" = ''
      zellij action rename-tab (basename (pwd))
    '';
    programs.nushell.extraConfig = ''
      def ,tt [] {
        zellij action rename-tab (pwd | path basename)
      }
    '';
  };
}
