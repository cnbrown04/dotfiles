require("caleb")

vim.o.autoread = true
vim.o.updatetime = 250
local cursor_file_watch = vim.api.nvim_create_augroup("CursorFileWatch", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = cursor_file_watch,
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})
vim.cmd("colorscheme dawnfox")
