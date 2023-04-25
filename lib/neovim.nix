{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
  };

  xdg.configFile."nvim".source = builtins.fetchGit {
    url = "https://github.com/AstroNvim/AstroNvim.git";
    ref = "refs/tags/v3.10.3";
    shallow = true;
  };
}
