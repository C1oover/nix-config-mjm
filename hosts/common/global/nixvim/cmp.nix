{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.x.nixvim;
in {
  programs.nixvim = lib.mkIf cfg.enableIde {
    extraConfigLuaPre = ''
      local function has_words_before()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
      end
    '';
    plugins.nvim-cmp = {
      enable = true;
      formatting.fields = ["kind" "abbr" "menu"];
      snippet.expand = "luasnip";
      preselect = "None";
      mapping = {
        "<Up>" = "cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select }";
        "<Down>" = "cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select }";
        "<C-p>" = "cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }";
        "<C-n>" = "cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }";
        "<C-k>" = "cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }";
        "<C-j>" = "cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }";
        "<C-u>" = {
          action = "cmp.mapping.scroll_docs(-4)";
          modes = ["i" "c"];
        };
        "<C-d>" = {
          action = "cmp.mapping.scroll_docs(4)";
          modes = ["i" "c"];
        };
        "<C-Space>" = {
          action = "cmp.mapping.complete()";
          modes = ["i" "c"];
        };
        "<C-y>" = "cmp.config.disable";
        "<C-e>" = "cmp.mapping { i = cmp.mapping.abort(), c = cmp.mapping.close() }";
        "<CR>" = "cmp.mapping.confirm { select = false }";
        "<Tab>" = {
          action = ''
            function(fallback)
              local luasnip = require("luasnip")
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              elseif has_words_before() then
                cmp.complete()
              else
                fallback()
              end
            end
          '';
          modes = ["i" "s"];
        };
        "<S-Tab>" = {
          action = ''
            function(fallback)
              local luasnip = require("luasnip")
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end
          '';
          modes = ["i" "s"];
        };
      };
      sources = [
        {
          name = "nvim_lsp";
          priority = 1000;
        }
        {
          name = "luasnip";
          priority = 750;
        }
        {
          name = "buffer";
          priority = 500;
        }
        {
          name = "path";
          priority = 250;
        }
      ];
    };

    plugins.cmp-buffer.enable = true;
    plugins.cmp-nvim-lsp.enable = true;
    plugins.cmp-path.enable = true;
    plugins.luasnip.enable = true;

    extraPlugins = with pkgs.vimPlugins; [friendly-snippets];
    extraConfigLuaPost = ''
      require("luasnip.loaders.from_vscode").lazy_load()
    '';

    colorschemes.catppuccin.integrations.cmp = true;
  };
}
