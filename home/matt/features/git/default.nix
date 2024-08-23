{
  lib,
  pkgs,
  config,
  ...
}:
let
  git-scripts = pkgs.callPackage ./scripts { };
in
{
  home.packages = builtins.attrValues {
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
        credentialStore = lib.mkIf pkgs.stdenv.isLinux "secretservice";
        "https://git.midna.dev" = {
          gitLabDevClientId = "2c4d82734ab055ae7ef0d2b1d1a596170d87e28ef4578a99de8298bdfdae52e9";
          gitLabDevClientSecret = "f4a3f4ef523cc1a20313464ba0a48d6185a11247f4c66091229760284685b1c5";
          provider = "gitlab";
        };
      };
    };
    userName = "Matt Moriarity";
    userEmail = lib.mkDefault "matt@mattmoriarity.com";
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

      aliases = {
        unpushed = [
          "log"
          "-r"
          "branches() & ~(main | remote_branches())"
        ];
        history = [
          "log"
          "-r"
          "::@"
        ];
        hist = [ "history" ];
        h = [ "history" ];
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
    custom.jj = {
      command = ''
        jj log -r@ -l1 --ignore-working-copy --no-graph --color always  -T '
          separate(" ",
            branches.map(|x| if(
                x.name().substr(0, 10).starts_with(x.name()),
                x.name().substr(0, 10),
                x.name().substr(0, 9) ++ "…")
              ).join(" "),
            tags.map(|x| if(
                x.name().substr(0, 10).starts_with(x.name()),
                x.name().substr(0, 10),
                x.name().substr(0, 9) ++ "…")
              ).join(" "),
            surround("\"","\"",
              if(
                 description.first_line().substr(0, 24).starts_with(description.first_line()),
                 description.first_line().substr(0, 24),
                 description.first_line().substr(0, 23) ++ "…"
              )
            ),
            if(conflict, "conflict"),
            if(divergent, "divergent"),
            if(hidden, "hidden"),
          )
        '
      '';
      detect_folders = [ ".jj" ];
      symbol = "@ ";
    };
    custom.jjstate = {
      command = ''
        jj log -r@ -l1 --no-graph -T "" --stat | tail -n1 | sd "(\d+) files? changed, (\d+) insertions?\(\+\), (\d+) deletions?\(-\)" " ''${1}m ''${2}+ ''${3}-" | sd " 0." ""
      '';
      detect_folders = [ ".jj" ];
    };
  };

  home.shellAliases = {
    ",jp" = "jj git push";
    ",jpc" = "jj git push --change @-";
    ",jpm" = "jj branch set main -r @- && jj git push";
    ",jum" = "jj git fetch && jj rebase -d main";
    ",jrm" = "jj rebase -d main";
  };
  programs.nushell.shellAliases = {
    ",jp" = "jj git push";
    ",jpc" = "jj git push --change @-";
    ",jrm" = "jj rebase -d main";
  };
  programs.nushell.extraConfig = ''
    def ,jpm [] {
      jj branch set main -r @-
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

    source ${
      pkgs.runCommand "jj-completions" { } ''
        ${pkgs.jujutsu}/bin/jj util completion nushell > $out
      ''
    }
  '';
}
