local utils = require("astronvim.utils")

return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    if not opts.ensure_installed then
      opts.ensure_installed = {}
    end

    require("astronvim.utils").list_insert_unique(opts.ensure_installed, {
      "bash",
      "dockerfile",
      "eex",
      "elixir",
      "gitcommit",
      "gitignore",
      "graphql",
      "heex",
      "json",
      "lua",
      "markdown",
      "nix",
      "toml",
      "yaml",
    })
  end,
}
