{
  programs.nixvim = {
    plugins.lsp = {
      enable = true;
      servers.bashls.enable = true;
      servers.elixirls.enable = true;
      servers.jsonls.enable = true;
      servers.yamlls.enable = true;
    };
    plugins.lsp-format = {
      enable = true;
    };
    maps = {
      visual = {
        "<leader>la" = {
          lua = true;
          action = "function() vim.lsp.buf.code_action() end";
          desc = "LSP code action";
        };
      };
      normal = {
        "<leader>ld" = {
          lua = true;
          action = "function() vim.diagnostic.open_float() end";
          desc = "Hover diagnostics";
        };
        "<leader>lD" = {
          lua = true;
          action = "function() require('telescope.builtin').diagnostics() end";
          desc = "Search diagnostics";
        };
        "[d" = {
          lua = true;
          action = "function() vim.diagnostic.goto_prev() end";
          desc = "Previous diagnostic";
        };
        "]d" = {
          lua = true;
          action = "function() vim.diagnostic.goto_next() end";
          desc = "Next diagnostic";
        };
        "<leader>la" = {
          lua = true;
          action = "function() vim.lsp.buf.code_action() end";
          desc = "LSP code action";
        };
        "gd" = {
          lua = true;
          action = "function() require('telescope.builtin').lsp_definitions() end";
          desc = "Show the definition of current symbol";
        };
        "gD" = {
          lua = true;
          action = "function() vim.lsp.buf.declaration() end";
          desc = "Declaration of current symbol";
        };
        "K" = {
          lua = true;
          action = "function() vim.lsp.buf.hover() end";
          desc = "Hover symbol details";
        };
        "gI" = {
          lua = true;
          action = "function() require('telescope.builtin').lsp_implementations() end";
          desc = "Implementation of current symbol";
        };
        "gr" = {
          lua = true;
          action = "function() require('telescope.builtin').lsp_references() end";
          desc = "References of current symbol";
        };
        "<leader>lR" = {
          lua = true;
          action = "function() require('telescope.builtin').lsp_references() end";
          desc = "Search references";
        };
        "<leader>lr" = {
          lua = true;
          action = "function() vim.lsp.buf.rename() end";
          desc = "Rename current symbol";
        };
        "<leader>lh" = {
          lua = true;
          action = "function() vim.lsp.buf.signature_help() end";
          desc = "Signature help";
        };
        "gT" = {
          lua = true;
          action = "function() require('telescope.builtin').lsp_type_definitions() end";
          desc = "Definition of current type";
        };
        "<leader>lG" = {
          lua = true;
          action = ''
            function()
              vim.ui.input({ prompt = "Symbol Query: " }, function(query)
                if query then require('telescope.builtin').lsp_workspace_symbols { query = query } end
              end)
            end
          '';
          desc = "Search workspace symbols";
        };
      };
    };
  };
}
