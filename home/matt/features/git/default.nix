{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  jjfind = pkgs.writeShellApplication {
    name = "jjfind";
    runtimeInputs = with pkgs; [jujutsu fzf coreutils];
    text = ''
      jj log --no-graph --color never -T 'change_id ++ " " ++ description.first_line() ++ "\n"' "$@" \
      | fzf --with-nth 2.. \
      | cut -d' ' -f1
    '';
  };

  jco = pkgs.writeShellApplication {
    name = "jco";
    runtimeInputs = [pkgs.jujutsu jjfind];
    text = ''
      jj new "$(jjfind "$@")"
    '';
  };
in {
  home.packages = with pkgs; [
    git-credential-manager
    watchman
    jjfind
    jco
  ];

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

  programs.zsh.plugins = [
    {
      name = "forgit";
      src = "${pkgs.zsh-forgit}/share/zsh/zsh-forgit";
    }
  ];

  programs.mr = {
    enable = true;
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user.name = config.programs.git.userName;
      user.email = config.programs.git.userEmail;
      ui.default-command = "log";
      core.fsmonitor = "watchman";

      aliases = {
        unpushed = ["log" "-r" "branches() & ~(main | remote_branches())"];
      };
    };
  };

  home.shellAliases = {
    jj-push = "jj branch set main -r @- && jj git push";
    jj-pull = "jj git fetch && jj rebase -d main";
  };
}
