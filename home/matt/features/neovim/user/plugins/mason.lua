return {
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "bashls",
        "docker_compose_language_service",
        "dockerls",
        "elixirls",
        "jsonls",
        "lua_ls",
        "yamlls",
      },
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = {
      ensure_installed = {
        "editorconfig-checker",
        "prettierd",
        "shellcheck",
        "shfmt",
        "stylua",
      },
    },
  },
}
