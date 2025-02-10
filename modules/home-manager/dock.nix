{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    concatMapStrings
    elem
    hasSuffix
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.home.dock;
  stdenv = pkgs.stdenv;

  systemApps = [
    "Mail"
    "Messages"
    "Utilities/Terminal"
  ];
in
{
  options = {
    home.dock.enable = mkOption {
      description = "Enable dock";
      default = stdenv.isDarwin;
      example = false;
    };

    home.dock.entries = mkOption {
      description = "Entries on the Dock";
      type =
        with types;
        listOf (
          submodule (
            { config, ... }:
            {
              options = {
                app = mkOption {
                  type = nullOr str;
                  default = null;
                };

                package = mkOption {
                  type = nullOr package;
                  default = null;
                };

                path = mkOption { type = str; };

                section = mkOption {
                  type = str;
                  default = "apps";
                };
                options = mkOption {
                  type = str;
                  default = "";
                };
              };

              config = mkMerge [
                (mkIf (config.app != null) {
                  path =
                    let
                      prefix =
                        if elem config.app systemApps then
                          "/System"
                        else if config.package != null then
                          "${config.package}"
                        else
                          "";
                    in
                    "${prefix}/Applications/${config.app}.app";
                })
              ];
            }
          )
        );
      readOnly = true;
    };
  };

  config = mkIf cfg.enable (
    let
      du = "env PYTHONIOENCODING=utf-8 ${pkgs.dockutil}/bin/dockutil ${config.home.homeDirectory}";
      normalize = path: if hasSuffix ".app" path then path + "/" else path;
      entryURI =
        path:
        "file://"
        + (builtins.replaceStrings
          # TODO: This is entirely too naive and works only with the bundles that I have seen on my system so far:
          [
            " "
            "!"
            ''"''
            "#"
            "$"
            "%"
            "&"
            "'"
            "("
            ")"
          ]
          [
            "%20"
            "%21"
            "%22"
            "%23"
            "%24"
            "%25"
            "%26"
            "%27"
            "%28"
            "%29"
          ]
          (normalize path)
        );
      wantURIs = pkgs.writeText "dock-uris" (
        concatMapStrings (entry: ''
          ${entryURI entry.path}
        '') cfg.entries
      );
      createEntries = concatMapStrings (entry: ''
        ${du} --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}
      '') cfg.entries;
    in
    {
      home.activation.setupDock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo >&2 "Setting up persistent dock items..."
        haveURIs="$(${du} --list | ${pkgs.coreutils}/bin/cut -f2)"
        if ! diff -wu <(echo -n "$haveURIs") ${wantURIs} >&2 ; then
          echo >&2 "Resetting Dock."
          ${du} --no-restart --remove all
          ${createEntries}
          /usr/bin/killall Dock
        else
          echo >&2 "Dock is how we want it."
        fi
      '';
    }
  );
}
