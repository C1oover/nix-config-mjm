{
  programs.k9s = {
    enable = true;
    catppuccin.enable = true;
  };

  programs.nushell.extraConfig = ''
    def --wrapped k9s [...args] {
      do {
        hide-env SSH_AUTH_SOCK
        ^k9s ...$args
      }
    }
  '';
}
