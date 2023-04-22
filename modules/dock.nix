{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.home.dock;
  stdenv = pkgs.stdenv;
in
{
  options = {
    home.dock.enable = mkOption {
      description = "Enable dock";
      default = stdenv.isDarwin;
      example = false;
    };

    home.dock.entries = mkOption
      {
        description = "Entries on the Dock";
        type = with types; listOf (submodule {
          options = {
            path = lib.mkOption { type = str; };
            section = lib.mkOption {
              type = str;
              default = "apps";
            };
            options = lib.mkOption {
              type = str;
              default = "";
            };
          };
        });
        readOnly = true;
      };
  };

  config =
    mkIf (cfg.enable)
      (
        let
          du = "env PYTHONIOENCODING=utf-8 ${pkgs.dockutil}/bin/dockutil";
          normalize = path: if hasSuffix ".app" path then path + "/" else path;
          entryURI = path: "file://" + (builtins.replaceStrings
            # TODO: This is entirely too naive and works only with the bundles that I have seen on my system so far:
            [" "   "!"   "\""  "#"   "$"   "%"   "&"   "'"   "("   ")"]
            ["%20" "%21" "%22" "%23" "%24" "%25" "%26" "%27" "%28" "%29"]
            (normalize path)
          );
          wantURIs = concatMapStrings
            (entry: "${entryURI entry.path}\n")
            cfg.entries;
          createEntries = concatMapStrings
            (entry: "${du} --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n")
            cfg.entries;
        in
        {
          home.activation.setupDock = hm.dag.entryAfter ["writeBoundary"] ''
            echo >&2 "Setting up persistent dock items..."
            haveURIs="$(${du} --list | ${pkgs.coreutils}/bin/cut -f2)"
            if ! diff -wu <(echo -n "$haveURIs") <(echo -n '${wantURIs}') >&2 ; then
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
