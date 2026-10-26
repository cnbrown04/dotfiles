local M = {}

-- Popup background: Ghostty's popup-opacity shader turns this exact color into
-- #1a1a1a at 75% opacity (see ~/.config/ghostty/shaders/popup-opacity.glsl).
local popup_bg = "#1a1a1b"

-- cyberdream UI, transparent so Ghostty's translucent background shows
-- through, with classic Monokai syntax colors (config/monokai-syntax.lua).
function M.setup()
	local ok, cyberdream = pcall(require, "cyberdream")
	if not ok then
		return
	end

	cyberdream.setup({
		transparent = true,
		terminal_colors = true,
		overrides = function(colors)
			return vim.tbl_extend("force", require("config.monokai-syntax"), {
				NormalFloat = { fg = colors.fg, bg = popup_bg },
				FloatBorder = { fg = colors.bg_highlight, bg = popup_bg },
				FloatTitle = { fg = colors.blue, bg = popup_bg },
				Pmenu = { fg = colors.fg, bg = popup_bg },
			})
		end,
	})

	vim.cmd.colorscheme("cyberdream")
end

return M
