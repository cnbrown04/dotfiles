local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = false
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Appearance
opt.fillchars = { eob = " " }
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Files
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.local/state/nvim/undo")

-- Completion
opt.completeopt = "menuone,noinsert,noselect"
opt.pumheight = 10

-- Misc
opt.mouse = "a"
opt.mousemoveevent = true
opt.clipboard = "unnamedplus"
opt.updatetime = 250
opt.timeoutlen = 300
opt.showmode = false  -- shown by statusline instead

-- colorscheme: config/owl-theme.lua (opaque Light Owl)
