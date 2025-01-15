{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    optional
    ;
  cfg = config.mjm.git;
in
{
  options.mjm.git = {
    enableWatchman = mkEnableOption "watchman for jujutsu" // {
      default = true;
    };

    enableMeld = mkEnableOption "meld for jujutsu" // {
      default = config.mjm.desktop.enable;
    };
  };

  config = mkIf cfg.enable {
    home.packages = optional cfg.enableMeld pkgs.meld ++ optional cfg.enableWatchman pkgs.watchman;

    programs.jujutsu = {
      enable = true;
      settings = {
        user.name = config.programs.git.userName;
        user.email = config.programs.git.userEmail;

        ui = {
          default-command = "log";
          diff.format = "git";
          diff-editor = ":builtin";
          merge-editor = mkIf cfg.enableMeld "meld";
        };

        core.fsmonitor = mkIf cfg.enableWatchman "watchman";

        revset-aliases = {
          "merge_base(x)" = "fork_point(trunk() | x)";
        };

        aliases = {
          unpushed = [
            "log"
            "-r"
            "bookmarks() & ~(main | remote_bookmarks())"
          ];
          history = [
            "log"
            "-r"
            "::@"
          ];
          hist = [ "history" ];
          h = [ "history" ];
          wc = [
            "log"
            "-r"
            "trunk()..@"
          ];
          dc = [
            "diff"
            "--from"
            "merge_base(@-)"
            "--to"
            "@-"
          ];
          di = [
            "diff"
            "--from"
            "merge_base(@)"
            "--to"
            "@"
          ];
        };
        revsets = {
          log = "@ | trunk() | ancestors(trunk()..(visible_heads() & mine() & ~tags()), 2)";
        };
      };
    };

    programs.nushell.shellAliases = {
      ",jgf" = "jj git fetch";
      ",jp" = "jj git push";
      ",jrm" = "jj rebase -d main";
    };
    programs.nushell.extraConfig = ''
      def ,jpc [] {
        let has_changes = (jj log -r@ -n 1 --no-graph -T 'if(!empty, "has changes")') != ""
        let has_description = (jj log -r@ -n 1 --no-graph -T 'if(description, "has description")') != ""
        if not $has_changes {
          jj git push --change @-
        } else if $has_description {
          jj git push --change @
        } else {
          error make {
            msg: "not pushing because the working copy has undescribed changes"
            help: "Either use 'jj describe' to describe the changes, or 'jj squash' them into a previous change."
          }
        }
      }

      def ,jpb [] {
        let bookmark = jj log -r '::@ & bookmarks()' --no-graph -T local_bookmarks -n 1 | str trim -r -c '*'
        jj bookmark set $bookmark -r @-
        try {
          jj git push
        } catch {
          jj undo
        }
      }

      def ,ju [] {
        jj git fetch
        jj rebase -d 'trunk()'
      }

      def --wrapped ,jr [...rest] {
        jj rebase -d (,jf) ...$rest
      }

      def --wrapped ,je [...rest] {
        jj edit (,jf ...$rest)
      }
    '';
  };
}
