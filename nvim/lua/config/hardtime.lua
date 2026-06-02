local M = {}

local configured = false

function M.setup()
	if configured then
		return
	end

	local ok, hardtime = pcall(require, "hardtime")
	if not ok then
		return
	end

	hardtime.setup({
		disable_mouse = false,
		-- Allow arrow keys in normal/insert (default disables them).
		disabled_keys = {
			["<Up>"] = false,
			["<Down>"] = false,
			["<Left>"] = false,
			["<Right>"] = false,
		},
		-- No repeat cooldown on movement keys.
		restricted_keys = {
			["h"] = false,
			["j"] = false,
			["k"] = false,
			["l"] = false,
			["+"] = false,
			["gj"] = false,
			["gk"] = false,
			["<C-M>"] = false,
			["<C-N>"] = false,
			["<C-P>"] = false,
		},
		disabled_filetypes = {
			["neo-tree"] = true,
			help = true,
			notify = true,
			noice = true,
			lspinfo = true,
			qf = true,
		},
	})

	configured = true
end

return M
