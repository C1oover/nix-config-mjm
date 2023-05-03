return {
	n = {
		["<leader>kf"] = {
			function()
				vim.fn.setreg("+", vim.fn.expand("%"))
			end,
			desc = "Copy relative path",
		},
		["<leader>TA"] = {
			function()
				os.execute(
					"kitty @ --to="
					.. os.getenv("KITTY_LISTEN_ON")
					.. " launch --type=overlay --cwd=current zsh -l -i -c 'docker compose exec slab_1 mix test.all; read'"
				)
			end,
			desc = "Test entire project",
		},
		["<leader>TF"] = {
			function()
				os.execute(
					"kitty @ --to="
					.. os.getenv("KITTY_LISTEN_ON")
					.. " launch --type=overlay --cwd=current zsh -l -i -c 'docker compose exec slab_1 mix test "
					.. vim.fn.expand("%")
					.. "; read'"
				)
			end,
			desc = "Test current file",
		},
		["<leader>TL"] = {
			function()
				os.execute(
					"kitty @ --to="
					.. os.getenv("KITTY_LISTEN_ON")
					.. " launch --type=overlay --cwd=current zsh -l -i -c 'docker compose exec slab_1 mix test "
					.. vim.fn.expand("%")
					.. ":"
					.. vim.api.nvim_win_get_cursor(0)[1]
					.. "; read'"
				)
			end,
			desc = "Test current line",
		},
	},
}
