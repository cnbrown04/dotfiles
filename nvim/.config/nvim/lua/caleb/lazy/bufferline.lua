return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local function listed_real_buffers()
      local bufs = {}
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buflisted and vim.bo[b].buftype == "" then
          table.insert(bufs, b)
        end
      end
      return bufs
    end

    local function safe_bufdelete(n)
      -- If you delete the last listed "real" buffer while it's current,
      -- Neovim can exit (especially when the window would become empty).
      -- Ensure there's always another buffer to show first.
      if n == vim.api.nvim_get_current_buf() then
        local listed = listed_real_buffers()
        if #listed <= 1 then
          vim.cmd("enew")
        end
      end

      local ok, Snacks = pcall(require, "snacks")
      if ok and Snacks.bufdelete then
        return Snacks.bufdelete(n)
      end
      pcall(vim.cmd, "bdelete " .. n)
    end

    local function diagnostic_icons()
      local ok, LazyVim = pcall(require, "lazyvim.config")
      if ok and LazyVim.icons and LazyVim.icons.diagnostics then
        return LazyVim.icons.diagnostics
      end
      return { Error = "E", Warn = "W", Info = "I", Hint = "H" }
    end

    require("bufferline").setup({
      options = {
        close_command = safe_bufdelete,
        right_mouse_command = safe_bufdelete,
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        diagnostics_indicator = function(_, _, diag)
          local icons = diagnostic_icons()
          local ret = (diag.error and icons.Error .. diag.error .. " " or "")
            .. (diag.warning and icons.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
          { filetype = "snacks_layout_box" },
        },
        get_element_icon = function(opts)
          local ok, LazyVim = pcall(require, "lazyvim.config")
          if ok and LazyVim.icons and LazyVim.icons.ft then
            return LazyVim.icons.ft[opts.filetype]
          end
        end,
      },
    })
  end,
}

