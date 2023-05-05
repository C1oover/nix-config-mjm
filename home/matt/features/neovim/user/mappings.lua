local run_last_test = function()
	os.execute(
		"kitty @ --to="
		.. os.getenv("KITTY_LISTEN_ON")
		.. " launch --type=overlay --cwd=current zsh -l -i -c 'docker compose exec slab_1 mix "
		.. vim.g.my_last_test
		.. "; read'"
	)
end

return {
	n = {
		["<leader>kf"] = {
			function()
				vim.fn.setreg("+", vim.fn.expand("%"))
			end,
			desc = "Copy relative path",
		},
		["<leader>TT"] = { run_last_test, desc = "Re-run last test" },
		["<leader>TA"] = {
			function()
				vim.g.my_last_test = "test.all"
				run_last_test()
			end,
			desc = "Test entire project",
		},
		["<leader>TF"] = {
			function()
				vim.g.my_last_test = "test " .. vim.fn.expand("%")
				run_last_test()
			end,
			desc = "Test current file",
		},
		["<leader>TL"] = {
			function()
				vim.g.my_last_test = "test " .. vim.fn.expand("%") .. ":" .. vim.api.nvim_win_get_cursor(0)[1]
				run_last_test()
			end,
			desc = "Test current line",
		},
	},
}
