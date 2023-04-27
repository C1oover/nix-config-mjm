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
    ref = "refs/tags/v3.11.5";
    rev = "33b3119d98a9441ff73103cfb705c33122afb632";
    shallow = true;
  };
}
