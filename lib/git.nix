{ lib, ... }:

{
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
      http."https://gitlab.home.mattmoriarity.com".sslCAInfo = builtins.fetchurl "http://vault.service.consul:8200/v1/pki-homelab/ca/pem";
    };
    userName = "Matt Moriarity";
    userEmail = lib.mkDefault "matt@mattmoriarity.com";
  };
}
