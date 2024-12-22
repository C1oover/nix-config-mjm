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
  wrappedPkg =
    pkgs.writeShellScriptBin "nu" ''
      set +u

      ${optionalString pkgs.stdenv.isLinux ''[ -z "$__NIXOS_SET_ENVIRONMENT_DONE" ] && . /etc/set-environment''}
      ${optionalString pkgs.stdenv.isDarwin ''
        [ -z "$__NIX_DARWIN_SET_ENVIRONMENT_DONE" ] && . ${config.system.build.setEnvironment}
        ${optionalString config.homebrew.enable ''eval "$(${config.homebrew.brewPrefix}/brew shellenv)"''}
      ''}
      HM_VARS=/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      [ -f "$HM_VARS" ] && . "$HM_VARS"

      export SHELL=${lib.getExe cfg.package}
      exec $SHELL "$@"
    ''
    // {
      shellPath = "/bin/nu";
    };
in
{
  options.programs.nushell = {
    enable = mkOption {
      default = false;
      type = types.bool;
    };

    package = mkPackageOption pkgs "nushell" { };
    wrappedPackage = mkOption { type = types.package; };
  };

  config = mkIf cfg.enable {
    programs.nushell.wrappedPackage = wrappedPkg;

    environment.shells = [
      "/run/current-system/sw/bin/nu"
      "${wrappedPkg}/bin/nu"
    ];
  };
}
