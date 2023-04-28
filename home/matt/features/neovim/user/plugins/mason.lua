return {
	{
		"williamboman/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"elixirls",
				"lua_ls",
			},
		},
	},
	{
		"jay-babu/mason-null-ls.nvim",
		opts = {
			ensure_installed = {
				"editorconfig-checker",
				"shellcheck",
				"shfmt",
				"stylua",
			},
		},
	},
}
