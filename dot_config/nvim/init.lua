require("caleb")

vim.o.autoread = true
vim.o.updatetime = 250
local cursor_file_watch = vim.api.nvim_create_augroup("CursorFileWatch", { clear = true })

local function safe_checktime()
  -- checktime can be noisy when command-line window is active.
  if vim.fn.mode() == "c" then
    return
  end

  vim.cmd("checktime")
end

vim.api.nvim_create_autocmd({
  "FocusGained",
  "WinEnter",
  "BufEnter",
  "CursorHold",
  "CursorHoldI",
  "TermLeave",
}, {
  group = cursor_file_watch,
  pattern = "*",
  callback = safe_checktime,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = cursor_file_watch,
  pattern = "*",
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
    pcall(vim.cmd, "Neotree refresh")
  end,
})

if vim.g.cursor_file_watch_timer == nil then
  -- Fallback for tmux/pane switches where focus events are inconsistent.
  vim.g.cursor_file_watch_timer = vim.fn.timer_start(1000, function()
    safe_checktime()
  end, { ["repeat"] = -1 })
end

vim.cmd("colorscheme dawnfox")
