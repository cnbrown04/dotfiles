local M = {}

local function apply()
  -- Make core backgrounds transparent (both GUI + terminal colors).
  local transparent = { bg = "NONE", ctermbg = "NONE" }
  local hl = vim.api.nvim_set_hl

  hl(0, "Normal", transparent)
  hl(0, "NormalNC", transparent)
  hl(0, "SignColumn", transparent)
  hl(0, "FoldColumn", transparent)
  hl(0, "LineNr", transparent)
  hl(0, "CursorLineNr", transparent)
  hl(0, "EndOfBuffer", transparent)

  -- Floating windows / popups
  hl(0, "NormalFloat", transparent)
  hl(0, "FloatBorder", transparent)
  hl(0, "Pmenu", transparent)
  hl(0, "MsgArea", transparent)

  -- Common sidebars (safe even if plugin not installed)
  hl(0, "NeoTreeNormal", transparent)
  hl(0, "NeoTreeNormalNC", transparent)
  hl(0, "NeoTreeEndOfBuffer", transparent)

  -- Statusline / tabline (bufferline + lualine)
  hl(0, "StatusLine", transparent)
  hl(0, "StatusLineNC", transparent)
  hl(0, "TabLine", transparent)
  hl(0, "TabLineFill", transparent)
  hl(0, "TabLineSel", transparent)
  hl(0, "WinBar", transparent)
  hl(0, "WinBarNC", transparent)

  -- Noice / notify (keep popups consistent with transparent floats)
  hl(0, "NotifyBackground", transparent)

  -- Noice (various popup UIs)
  hl(0, "NoicePopup", transparent)
  hl(0, "NoicePopupBorder", transparent)
  hl(0, "NoiceCmdlinePopup", transparent)
  hl(0, "NoiceCmdlinePopupBorder", transparent)
  hl(0, "NoiceMini", transparent)
  hl(0, "NoiceMiniBorder", transparent)
  hl(0, "NoiceConfirm", transparent)
  hl(0, "NoiceConfirmBorder", transparent)
  hl(0, "NoiceCmdline", transparent)
  hl(0, "NoicePopupmenu", transparent)
  hl(0, "NoiceSplit", transparent)
  hl(0, "NoiceSplitBorder", transparent)

  -- Notify variants (depending on theme/plugin version)
  hl(0, "NotifyERRORBody", transparent)
  hl(0, "NotifyWARNBody", transparent)
  hl(0, "NotifyINFOBody", transparent)
  hl(0, "NotifyDEBUGBody", transparent)
  hl(0, "NotifyTRACEBody", transparent)
end

function M.setup()
  -- Blend floating UI a bit for “glassy” look.
  vim.opt.winblend = 12
  vim.opt.pumblend = 12

  local group = vim.api.nvim_create_augroup("TransparentBackground", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      apply()
    end,
  })

  -- Re-apply after lazy-loaded UI plugins (like Noice) set their own highlights.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "VeryLazy", "LazyDone" },
    callback = function()
      apply()
    end,
  })

  -- Noice defines/links its highlight groups during setup. Re-assert our bg after that.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "NoiceStarted",
    callback = function()
      apply()
    end,
  })

  vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
    group = group,
    callback = function()
      apply()
    end,
  })

  -- Apply immediately too (in case colorscheme already set)
  apply()
end

return M

