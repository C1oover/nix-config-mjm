return {
	n = {
		["<leader>kf"] = {
			function()
				vim.fn.setreg("+", vim.fn.expand("%"))
			end,
			desc = "Copy relative path",
		},
	},
}
