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
    ref = "refs/tags/v3.11.3";
    rev = "5d491ed2143abac1f3f40a607b6810919d1b5800";
    shallow = true;
  };
}
