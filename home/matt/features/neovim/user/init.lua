return {
	lsp = {
		servers = {
			"bashls",
			"docker_compose_language_service",
			"dockerls",
			"jsonls",
			"nil_ls",
			"yamlls",
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

		require("nvim-treesitter.configs").setup({
			highlight = { enable = true },
			incremental_selection = { enable = true },
			autotag = { enable = true },
			context_commentstring = { enable = true, enable_autocmd = false },
			indent = { enable = true },
		})
	end,
}
