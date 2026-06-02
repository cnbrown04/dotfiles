local M = {}

function M.setup()
	vim.diagnostic.config({
		underline = true,
		signs = true,
		virtual_text = false,
		severity_sort = true,
		float = {
			border = "rounded",
			source = true,
			header = "",
			prefix = "",
		},
	})
end

return M
