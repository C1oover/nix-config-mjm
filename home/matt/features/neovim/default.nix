{ pkgs, ... }:
let
  astronvim = builtins.fetchGit {
    url = "https://github.com/AstroNvim/AstroNvim.git";
    ref = "refs/tags/v3.11.5";
    rev = "33b3119d98a9441ff73103cfb705c33122afb632";
    shallow = true;
  };
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      vim-elixir
      (nvim-treesitter.withPlugins (p: [
        p.bash
        p.dockerfile
        p.eex
        p.elixir
        p.gitcommit
        p.gitignore
        p.graphql
        p.heex
        p.json
        p.lua
        p.markdown
        p.nix
        p.proto
        p.starlark
        p.toml
        p.yaml
      ]))
    ];
  };

  xdg.configFile."nvim".source = astronvim;
  xdg.configFile."astronvim/lua/user".source = ./user;

  home.packages = with pkgs; [
    rnix-lsp
    alejandra
    deadnix
    statix
  ];
}
