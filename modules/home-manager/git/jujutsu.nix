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
          mega = mkAlias (getExe jm);
          p = [ "git push" ];
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
          up = mkFishAlias "jj-up" ''
            jj git fetch
            jj rebase -d 'trunk()'
          '';
          f = mkFishAlias "jj-f" ''
            jj log --no-graph --color always -T 'if(description, change_id.short() ++ " " ++ description.first_line() ++ "\n")' $argv |
              sk --nth 2.. --ansi --preview 'jj show --color always {1}' |
              string split -f 1 ' '
          '';
        };
        revsets = {
          log = "@ | trunk() | ancestors(trunk()..(visible_heads() & mine() & ~tags()), 2)";
        };
      };
    };
  };
}
