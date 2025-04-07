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
    mkOption
    optional
    types
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

  mkAlias = script: [
    "util"
    "exec"
    "--"
    script
  ];
  mkFishAlias = name: text: mkAlias (pkgs.writers.writeFish name text);
in
{
  options.mjm.git = {
    enableWatchman = mkEnableOption "watchman for jujutsu" // {
      default = true;
    };

    enableMeld = mkEnableOption "meld for jujutsu" // {
      default = config.mjm.desktop.enable;
    };

    enableKaleidoscope = mkEnableOption "Kaleidoscope merge tool" // {
      default = pkgs.stdenv.isDarwin && config.mjm.desktop.enable;
    };

    mergeTool = mkOption {
      type = types.nullOr (
        types.enum [
          "meld"
          "ksdiff"
        ]
      );
      default =
        if cfg.enableKaleidoscope then
          "ksdiff"
        else if cfg.enableMeld then
          "meld"
        else
          null;
    };

    enableSigning = mkEnableOption "commit signing with SSH key" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.desktop.enable) {
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
          merge-editor = mkIf (cfg.mergeTool != null) cfg.mergeTool;
        };

        merge-tools.ksdiff = mkIf cfg.enableKaleidoscope {
          merge-args = [
            "--merge"
            "--output"
            "$output"
            "--base"
            "$base"
            "$left"
            "$right"
          ];
        };

        core.fsmonitor = mkIf cfg.enableWatchman "watchman";

        signing = mkIf cfg.enableSigning {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/id_ed25519.pub";
        };

        revset-aliases = {
          "merge_base(x)" = "fork_point(trunk() | x)";
        };

        aliases = {
          ll = [
            "log"
            "-r"
            "@ | trunk() | ancestors(reachable(@ | mine(), mutable()), 2)"
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
          mega = mkAlias (getExe jm);
          p = [
            "git"
            "push"
          ];
          pc = [
            "git"
            "push"
            "--change"
            "heads(description(glob:'?*') & ::@)"
          ];
          pb = mkFishAlias "jj-pb" ''
            jj bookmark move --from 'heads(::@ & bookmarks())' --to 'heads(description(glob:"?*") & ::@)'
            jj git push
            or jj undo
          '';
          pf = mkFishAlias "jj-pf" ''
            jj git push --branch (jj fb)
          '';
          up = mkFishAlias "jj-up" ''
            jj git fetch
            jj rebase -d 'trunk()'
          '';
          f = mkFishAlias "jj-f" ''
            jj log --no-graph --color always -T 'if(description, separate(" ", format_short_change_id_with_hidden_and_divergent_info(self), description.first_line(), if(conflict, label("conflict", "conflict"))) ++ "\n")' $argv |
              sk --nth 2.. --ansi --preview 'jj show --color always {1}' |
              string split -f 1 ' '
          '';
          fb = mkFishAlias "jj-fb" ''
            jj bookmark list --color always -t --quiet -T 'if(!remote && present, label("bookmark", name) ++ format_ref_targets(self) ++ "\n")' $argv |
              sk --ansi |
              string split -f 1 ':'
          '';
          e = mkFishAlias "jj-e" ''
            jj edit (jj f)
          '';
          n = mkFishAlias "jj-n" ''
            jj new (jj f)
          '';
        };
        revsets = {
          log = "@ | ancestors(reachable(@, mutable()), 2)";
        };

        fix.tools = {
          mix-format = {
            command = "mix format - --stdin-filename=$path";
            patterns = [
              "glob:'**/*.ex'"
              "glob:'**/*.exs'"
            ];
          };
        };
      };
    };
  };
}
