return {
  lsp = {
    servers = {
      "rnix",
    },
  },
  lazy = {
    performance = {
      reset_packpath = false,
      rtp = {
        reset = false,
      },
    },
  },
  polish = function()
    -- lazy.nvim disables the built-in package management,
    -- so we need to run it manually here to get plugins from Nix
    vim.cmd([[packloadall]])
  end,
}
