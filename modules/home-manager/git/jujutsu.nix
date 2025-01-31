{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    optional
    ;
  cfg = config.mjm.git;

  jm = pkgs.writeNuBin ",jm" {
    makeWrapperArgs = [
      "--prefix"
      ":"
      "PATH"
      (lib.makeBinPath [ pkgs.jujutsu ])
    ];
  } ./scripts/jm.nu;
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
    home.packages =
      [ jm ] ++ optional cfg.enableMeld pkgs.meld ++ optional cfg.enableWatchman pkgs.watchman;

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
          mega = [
            "util"
            "exec"
            "--"
            (getExe jm)
          ];
        };
        revsets = {
          log = "@ | trunk() | ancestors(trunk()..(visible_heads() & mine() & ~tags()), 2)";
        };
      };
    };

    programs.fish.shellAliases = {
      ",jp" = "jj git push";
      ",jpc" = "jj git push -c 'heads(description(glob:\"?*\") & ::@)'";
    };
    programs.fish.functions = {
      ",jpb" = ''
        jj bookmark move --from 'heads(::@ & bookmarks())' --to 'heads(description(glob:"?*") & ::@)'
        jj git push
        or jj undo
      '';

      ",ju" = ''
        jj git fetch
        jj rebase -d 'trunk()'
      '';

      ",jf" = ''
        jj log --no-graph --color always -T 'if(description, change_id.short() ++ " " ++ description.first_line() ++ "\n")' $argv |
          sk --nth 2.. --ansi --preview 'jj show --color always {1}' |
          string split -f 1 ' '
      '';
    };

    programs.nushell.shellAliases = {
      ",jgf" = "jj git fetch";
      ",jp" = "jj git push";
      ",jrm" = "jj rebase -d main";
    };
    programs.nushell.extraConfig = ''
      def ,jpc [] {
        jj git push --change 'heads(description(glob:"?*") & ::@)'
      }

      def ,jpb [] {
        jj bookmark move --from 'heads(::@ & bookmarks())' --to 'heads(description(glob:"?*") & ::@)'
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
