{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkPackageOption
    optionalString
    types
    ;

  cfg = config.programs.nushell;

  loadBashEnv =
    path: "${pkgs.bash-env-json}/bin/bash-env-json ${path} | from json | get env | load-env";
in
{
  options.programs.nushell = {
    enable = mkOption {
      default = false;
      type = types.bool;
    };

    package = mkPackageOption pkgs "nushell" { };

    setEnvironment = mkOption {
      type = types.lines;
      readOnly = true;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nushell ];

    environment.shells = [
      "/run/current-system/sw/bin/nu"
      "${pkgs.nushell}/bin/nu"
    ];

    programs.nushell.setEnvironment = ''
      ${optionalString pkgs.stdenv.isLinux ''
        if '__NIXOS_SET_ENVIRONMENT_DONE' not-in $env {
          ${loadBashEnv "/etc/set-environment"}
        }
      ''}
      ${optionalString pkgs.stdenv.isDarwin ''
        if '__NIX_DARWIN_SET_ENVIRONMENT_DONE' not-in $env {
          ${loadBashEnv "/etc/set-environment"}
        }
        ${optionalString config.homebrew.enable ''
          ${config.homebrew.brewPrefix}/brew shellenv | ${pkgs.bash-env-json}/bin/bash-env-json | from json | get env | load-env
        ''}
      ''}
    '';
  };
}
