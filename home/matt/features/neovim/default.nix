{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  enableNeovim = !config.programs.nixvim.enable;
in {
  programs.neovim = {
    enable = enableNeovim;
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

  xdg.configFile = lib.mkIf enableNeovim {
    "nvim".source = inputs.astronvim;
    "astronvim/lua/user".source = ./user;
  };

  home.packages = with pkgs;
    lib.mkIf enableNeovim [
      nil
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
