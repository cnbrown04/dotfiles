local M = {}

local function apply()
  -- Make core backgrounds transparent
  local transparent = { bg = "NONE" }
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

  -- Common sidebars (safe even if plugin not installed)
  hl(0, "NeoTreeNormal", transparent)
  hl(0, "NeoTreeNormalNC", transparent)
  hl(0, "NeoTreeEndOfBuffer", transparent)
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

  -- Apply immediately too (in case colorscheme already set)
  apply()
end

return M

