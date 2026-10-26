require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.diagnostics").setup()
require("config.lsp").setup()

vim.pack.add({
	"https://github.com/m4xshen/hardtime.nvim",
	"https://github.com/utilyre/barbecue.nvim",
	"https://github.com/SmiteshP/nvim-navic",
	"https://github.com/folke/noice.nvim",
	"https://github.com/rcarriga/nvim-notify",
	"https://github.com/lewis6991/hover.nvim",
})

require("config.noice").setup()
require("config.hardtime").setup()
require("config.hover").setup()

-- Colorscheme: cyberdream
vim.pack.add({ "https://github.com/scottmckendry/cyberdream.nvim" })
require("config.theme").setup()
require("config.barbecue").setup()

-- fff.nvim
vim.pack.add({ "https://github.com/dmtrKovalenko/fff.nvim" })

-- neo-tree
vim.pack.add({
	{
		src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
		version = vim.version.range("3"),
	},
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
})

local ok, neotree = pcall(require, "neo-tree")
if ok then
	neotree.setup({
		close_if_last_window = true,
		window = {
			width = 30,
			position = "left",
		},
		filesystem = {
			follow_current_file = { enabled = true },
			hijack_netrw_behavior = "open_default",
		},
	})
end

vim.g.fff = {
	lazy_sync = true,
	debug = { enabled = true, show_scores = true },
}

-- Keep plugins on their latest versions (daily, no confirmation).
require("config.autoupdate").setup()
