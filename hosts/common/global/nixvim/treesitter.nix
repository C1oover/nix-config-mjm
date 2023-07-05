{pkgs, ...}: {
  programs.nixvim = {
    plugins.treesitter = {
      enable = true;
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        dockerfile
        eex
        elixir
        gitcommit
        gitignore
        graphql
        hcl
        heex
        json
        lua
        markdown
        nix
        proto
        starlark
        terraform
        toml
        yaml
      ];

      incrementalSelection.enable = true;

      moduleConfig = {
        autotag.enable = true;
        indent = {
          enable = true;
          disable = ["elixir"];
        };
      };
    };

    plugins.nvim-autopairs = {
      enable = true;
      checkTs = true;
      tsConfig = {java = false;};
    };

    colorschemes.catppuccin.integrations.treesitter = true;
  };
}
