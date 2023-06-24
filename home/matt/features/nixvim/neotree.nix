{
  programs.nixvim = {
    maps.normal = {
      "<leader>e" = {
        action = "<cmd>Neotree toggle<cr>";
        desc = "Toggle Explorer";
      };
      "<leader>o" = {
        lua = true;
        action = ''
          function()
            if vim.bo.filetype == "neo-tree" then
              vim.cmd.wincmd "p"
            else
              vim.cmd.Neotree "focus"
            end
          end
        '';
        desc = "Toggle Explorer Focus";
      };
    };
    plugins.neo-tree = {
      enable = true;
      autoCleanAfterSessionRestore = true;
      closeIfLastWindow = true;
      defaultComponentConfigs = {
        indent.padding = 0;
      };
      filesystem = {
        followCurrentFile = true;
        hijackNetrwBehavior = "open_current";
        useLibuvFileWatcher = true;
      };
      sourceSelector = {
        contentLayout = "start";
        winbar = true;
      };
      window = {
        width = 30;
      };
    };

    colorschemes.catppuccin.integrations.neotree = true;
  };
}
