return {
  "rcarriga/nvim-notify",
  -- Load early so anything calling vim.notify gets the right UI
  lazy = false,
  priority = 1000,
  config = function()
    local notify = require("notify")
    notify.setup({
      -- Prevent "no default background color" warnings.
      -- This is only used for the 100% transparent case; actual window bg is set via winhighlight.
      background_colour = "#000000",
      on_open = function(win)
        -- winblend in terminals tends to darken towards the terminal default bg.
        -- Keep it at 0 so "transparent" highlight groups actually look transparent.
        pcall(vim.api.nvim_win_set_option, win, "winblend", 0)
        pcall(vim.api.nvim_win_set_option, win, "winhighlight", "Normal:NormalFloat,FloatBorder:FloatBorder")
      end,
    })
    vim.notify = notify
  end,
}

