{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    attrValues
    mkDefault
    mkEnableOption
    mkIf
    ;
  cfg = config.mjm.git;

  git-scripts = pkgs.callPackage ./scripts { };
in
{
  options.mjm.git = {
    enable = mkEnableOption "Git configuration";
  };

  config = mkIf cfg.enable {
    home.packages = attrValues {
      inherit git-scripts;
      inherit (pkgs)
        glab
        git-credential-manager
        meld
        watchman
        ;
    };

    programs.git = {
      enable = true;
      aliases = {
        st = "status -sb";
        ci = "commit --verbose";
        di = "diff";
        dc = "diff --cached";
      };
      diff-so-fancy.enable = true;
      extraConfig = {
        push = {
          default = "simple";
          autoSetupRemote = true;
        };
        help.autocorrect = 10;
        pull.rebase = false;
        credential = {
          helper = "manager";
          credentialStore = mkIf pkgs.stdenv.isLinux "secretservice";
          "https://git.midna.dev" = {
            gitLabDevClientId = "2c4d82734ab055ae7ef0d2b1d1a596170d87e28ef4578a99de8298bdfdae52e9";
            gitLabDevClientSecret = "f4a3f4ef523cc1a20313464ba0a48d6185a11247f4c66091229760284685b1c5";
            provider = "gitlab";
          };
        };
      };
      userName = "Matt Moriarity";
      userEmail = mkDefault "matt@mattmoriarity.com";
    };

    programs.jujutsu = {
      enable = true;
      settings = {
        user.name = config.programs.git.userName;
        user.email = config.programs.git.userEmail;

        ui = {
          default-command = "log";
          diff.format = "git";
          diff-editor = ":builtin";
          merge-editor = "meld";
        };

        core.fsmonitor = "watchman";

        revset-aliases = {
          "merge_base(x)" = "merge_base(trunk(), x)";
          "merge_base(a, b)" = "heads(..a & ..b)";
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

    programs.starship.settings = {
      git_branch.only_attached = true;
      git_commit.disabled = true;
      git_status.disabled = true;
      custom =
        let
          sd = lib.getExe pkgs.sd;
          mkStatusModule =
            {
              variable,
              style,
              symbol,
            }:
            {
              command = ''
                jj log -r@ -n 1 --no-graph -T "" --stat | tail -n1 | ${sd} "(\\d+) files? changed, (\\d+) insertions?\\(\\+\\), (\\d+) deletions?\\(-\\)" "''${${variable}}" | ${sd} "0" ""
              '';
              format = "[( ${symbol}$output)]($style)";
              style = "italic dimmed ${style}";
              detect_folders = [ ".jj" ];
            };
        in
        {
          jj = {
            command = ''
              jj log -r@ --no-graph --color always -T '
                label("working_copy",
                  concat(
                    separate(" ",
                      if(conflict, label("conflict", "conflict")),
                      if(empty, label("empty", "(empty)")),
                      if(description, description.first_line(), label(if(empty, "empty"), description_placeholder))
                    )
                  )
                )
              '
            '';
            style = "";
            detect_folders = [ ".jj" ];
            symbol = " @ ";
          };
          jj_added = mkStatusModule {
            variable = "2";
            style = "green";
            symbol = "▴";
          };
          jj_removed = mkStatusModule {
            variable = "3";
            style = "red";
            symbol = "▿";
          };
        };
    };

    programs.nushell.shellAliases = {
      ",jp" = "jj git push";
      ",jrm" = "jj rebase -d main";
    };
    programs.nushell.extraConfig = ''
      def ,jpm [] {
        jj bookmark set main -r @-
        try {
          jj git push
        } catch {
          jj undo
        }
      }

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

      def ,jum [] {
        jj git fetch
        jj rebase -d main
      }

      def --wrapped ,jr [...rest] {
        jj rebase -d (,jf) ...$rest
      }
    '';
  };
}
