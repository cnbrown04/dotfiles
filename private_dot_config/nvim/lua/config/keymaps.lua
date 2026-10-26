local map = vim.keymap.set

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- fff.nvim
map("n", "<leader>f", function() require("fff").find_files() end, { desc = "FFFind files" })
