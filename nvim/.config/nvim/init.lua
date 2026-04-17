require("caleb")

vim.o.autoread = true
vim.o.updatetime = 250
local cursor_file_watch = vim.api.nvim_create_augroup("CursorFileWatch", { clear = true })

local function safe_checktime()
  if vim.fn.mode() == "c" then
    return
  end
  vim.cmd("checktime")
end

-- Do not hook CursorHold/CursorHoldI: with low updatetime that runs checktime constantly while
-- idle and can spam reloads + FileChangedShellPost. Focus / entering buffers is enough.
vim.api.nvim_create_autocmd({
  "FocusGained",
  "WinEnter",
  "BufEnter",
  "TermLeave",
}, {
  group = cursor_file_watch,
  pattern = "*",
  callback = safe_checktime,
})

local last_disk_notify = {}
local DISK_NOTIFY_DEBOUNCE_SEC = 5

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = cursor_file_watch,
  pattern = "*",
  callback = function(args)
    local buf = args.buf
    local key = buf > 0 and buf or 0
    local now = os.time()
    local last = last_disk_notify[key]
    if last and (now - last) < DISK_NOTIFY_DEBOUNCE_SEC then
      return
    end
    last_disk_notify[key] = now
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
    pcall(vim.cmd, "Neotree refresh")
  end,
})
