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

	local map = vim.keymap.set

	map("n", "K", function()
		hover.open()
	end, { desc = "Hover" })

	map("n", "gK", function()
		hover.enter()
	end, { desc = "Enter hover window" })

	map("n", "<C-p>", function()
		hover.switch("previous")
	end, { desc = "Previous hover source" })

	map("n", "<C-n>", function()
		hover.switch("next")
	end, { desc = "Next hover source" })

	map({ "n", "i", "v" }, "<MouseMove>", function()
		hover.mouse()
	end, { desc = "Hover (mouse)" })

	configured = true
end

return M
