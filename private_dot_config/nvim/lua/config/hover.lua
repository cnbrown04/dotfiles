local M = {}

local configured = false

function M.setup()
	if configured then
		return
	end

	local ok, hover = pcall(require, "hover")
	if not ok then
		return
	end

	hover.config({
		preview_opts = {
			border = "rounded",
		},
		preview_window = false,
		title = true,
		mouse_delay = 200,
		providers = {
			"hover.providers.diagnostic",
			"hover.providers.lsp",
			"hover.providers.dap",
			"hover.providers.man",
			"hover.providers.dictionary",
		},
		mouse_providers = {
			"hover.providers.diagnostic",
			"hover.providers.lsp",
		},
	})

	configured = true
end

return M
