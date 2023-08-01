{
  lib,
  pkgs,
  config,
  ...
}: {
  home.packages = [
    pkgs.git-credential-manager
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
      http."https://gitlab.home.mattmoriarity.com".sslCAInfo = import ../../../../lib/vault/ca.nix;
      credential = {
        helper = "manager";
        credentialStore = lib.mkIf pkgs.stdenv.isLinux "secretservice";
        "https://gitlab.home.mattmoriarity.com" = {
          gitLabDevClientId = "2c4d82734ab055ae7ef0d2b1d1a596170d87e28ef4578a99de8298bdfdae52e9";
          gitLabDevClientSecret = "f4a3f4ef523cc1a20313464ba0a48d6185a11247f4c66091229760284685b1c5";
          provider = "gitlab";
        };
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
    };
    enableZshIntegration = true;
  };
}
