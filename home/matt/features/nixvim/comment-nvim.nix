{
  programs.nixvim = {
    plugins.comment-nvim = {
      enable = true;
    };
    maps.normal."<leader>/" = {
      action = "function() require('Comment.api').toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1) end";
      lua = true;
      desc = "Toggle comment line";
    };
    maps.visual."<leader>/" = {
      action = "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>";
      desc = "Toggle comment for selection";
    };
  };
}
