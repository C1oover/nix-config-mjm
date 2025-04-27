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

    xdg.configFile."zellij/config.kdl".source = pkgs.replaceVars ./zellij.kdl {
      copy_command = if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy";
    };
    xdg.configFile."zellij/layouts/default.kdl".source = ./default.kdl;

    programs.fish.functions.",tt" = ''
      zellij action rename-tab (basename (pwd))
    '';
    programs.nushell.extraConfig = ''
      def ,tt [] {
        zellij action rename-tab (pwd | path basename)
      }
    '';

    programs.fish.interactiveShellInit = ''
      function zellij_tab_name_update --on-variable PWD
        if set -q ZELLIJ
          command nohup zellij action rename-tab (basename (pwd)) >/dev/null 2>&1
        end
      end

      zellij_tab_name_update
    '';
  };
}
