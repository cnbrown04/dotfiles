local M = {}

local configured = false

function M.setup()
	if configured then
		return
	end

	local ok, barbecue = pcall(require, "barbecue")
	if not ok then
		return
	end

	barbecue.setup({
		exclude_filetypes = { "neo-tree", "help", "notify", "noice", "lspinfo", "qf" },
		theme = "auto",
	})

	configured = true
end

return M
