{ pkgs
, inputs
, ...
}: {
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
        p.hcl
        p.heex
        p.json
        p.lua
        p.markdown
        p.nix
        p.proto
        p.starlark
        p.terraform
        p.toml
        p.yaml
      ]))
    ];
  };

  xdg.configFile."nvim".source = inputs.astronvim;
  xdg.configFile."astronvim/lua/user".source = ./user;

  home.packages = with pkgs; [
    rnix-lsp
    alejandra
    deadnix
    statix

    nodePackages.bash-language-server
    docker-compose-language-service
    nodePackages.dockerfile-language-server-nodejs
    nodePackages.vscode-langservers-extracted
    nodePackages.yaml-language-server
  ];
}
