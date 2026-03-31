local function save()
  vim.cmd("write")
end

-- Save bindings.
--
-- Note: Many terminal emulators do NOT send <D-s> to Neovim.
-- We map a few common variants so whichever your terminal sends will work.
vim.keymap.set({ "n", "v" }, "<D-s>", save, { desc = "Save file" })
vim.keymap.set("i", "<D-s>", save, { desc = "Save file" })

vim.keymap.set({ "n", "v" }, "<M-s>", save, { desc = "Save file" })
vim.keymap.set("i", "<M-s>", save, { desc = "Save file" })

-- <C-s> works too, but may require `stty -ixon` in your shell to avoid terminal freeze.
vim.keymap.set({ "n", "v" }, "<C-s>", save, { desc = "Save file" })
vim.keymap.set("i", "<C-s>", save, { desc = "Save file" })
