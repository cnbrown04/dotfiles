local palette = require("config.owl-palette")

local M = {}

function M.apply_owl_overrides()
	local p = palette
	local bg = palette.strip_alpha(p.bg)
	local fg = palette.strip_alpha(p.fg)
	local blue = palette.strip_alpha(p.blue)
	local border = palette.strip_alpha(p.border)
	local cursor_fg = palette.strip_alpha(p.cursor)

	vim.api.nvim_set_hl(0, "Normal", { fg = fg, bg = bg })
	vim.api.nvim_set_hl(0, "Cursor", { fg = bg, bg = cursor_fg })
	vim.api.nvim_set_hl(0, "lCursor", { fg = bg, bg = cursor_fg })
	vim.api.nvim_set_hl(0, "CursorIM", { fg = bg, bg = cursor_fg })
	vim.api.nvim_set_hl(0, "TermCursor", { fg = bg, bg = cursor_fg })
	vim.api.nvim_set_hl(0, "FloatTitle", { fg = blue, bg = bg, bold = true })
	vim.api.nvim_set_hl(0, "FloatBorder", { fg = border, bg = bg })
	vim.api.nvim_set_hl(0, "LineNr", { fg = palette.strip_alpha(p.overlay_0), bg = bg })
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = fg, bg = bg, bold = true })
end

function M.apply()
	if vim.g.owl_theme_active ~= "light-owl" then
		require("light-owl").setup({ transparent_background = false })
		vim.cmd.colorscheme("light-owl")
		vim.g.owl_theme_active = "light-owl"
	end
	M.apply_owl_overrides()
end

function M.setup_autocmds()
	local group = vim.api.nvim_create_augroup("owl_theme", { clear = true })
	vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "UIEnter" }, {
		group = group,
		callback = function()
			M.apply()
		end,
	})
end

return M
