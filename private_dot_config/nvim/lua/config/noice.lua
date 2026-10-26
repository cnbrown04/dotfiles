local M = {}

local configured = false

function M.setup()
	if configured then
		return
	end

	local ok, noice = pcall(require, "noice")
	if not ok then
		return
	end

	noice.setup({
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
			hover = {
				enabled = false,
			},
			signature = {
				enabled = true,
				auto_open = {
					enabled = true,
					trigger = true,
					throttle = 50,
				},
			},
			progress = {
				enabled = true,
			},
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			lsp_doc_border = true,
		},
	})

	configured = true
end

return M
