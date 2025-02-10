{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkBefore mkIf;
  cfg = config.mjm.shell;
in
{
  config = mkIf (cfg.enable && osConfig.programs.nushell.enable) {
    programs.nushell = {
      enable = true;
      extraConfig = mkBefore ''
        ${osConfig.programs.nushell.setEnvironment}

        let hm_vars = $"/etc/profiles/per-user/($env.USER)/etc/profile.d/hm-session-vars.sh"
        if ($hm_vars | path exists) {
          ${pkgs.bash-env-json}/bin/bash-env-json $hm_vars | from json | get env | load-env
        }

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

    home.file = mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/nushell".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/nushell";
    };
  };
}
