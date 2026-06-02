local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  group = augroup("trim_whitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, pos)
  end,
})

-- Restore cursor position on file open
autocmd("BufReadPost", {
  group = augroup("restore_cursor", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-create parent directories on save
autocmd("BufWritePre", {
  group = augroup("auto_create_dir", { clear = true }),
  callback = function(ev)
    local dir = vim.fn.fnamemodify(ev.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- Close certain windows with q
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "man", "qf", "notify", "lspinfo", "noice" },
  callback = function(ev)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- neo-tree: open sidebar on startup
autocmd("VimEnter", {
  group = augroup("neotree_start", { clear = true }),
  callback = function()
    local has_file = vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv(0)) == 0
    vim.schedule(function()
      -- check if neo-tree is already open (hijack_netrw opened it for a dir arg)
      local neotree_open = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
          neotree_open = true
          break
        end
      end

      if not neotree_open then
        vim.cmd("Neotree show")
      end

      if has_file then
        -- focus the file window on the right
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "neo-tree" then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
      else
        -- no file: focus neo-tree
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
      end
    end)
  end,
})

-- quit all when the last real (non-neo-tree) window is closed
autocmd("QuitPre", {
  group = augroup("neotree_quit_all", { clear = true }),
  callback = function()
    local real_wins = 0
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "neo-tree" then
        real_wins = real_wins + 1
      end
    end
    if real_wins == 1 then
      vim.cmd("qa")
    end
  end,
})

-- neo-tree: setup after install/update
autocmd("PackChanged", {
  group = augroup("neotree_install", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "neo-tree.nvim" and (kind == "install" or kind == "update") then
      if not ev.data.active then vim.cmd.packadd("neo-tree.nvim") end
      local ok, neotree = pcall(require, "neo-tree")
      if ok then
        neotree.setup({
          close_if_last_window = true,
          window = { width = 30, position = "left" },
          filesystem = {
            follow_current_file = { enabled = true },
            hijack_netrw_behavior = "open_current",
          },
        })
      end
    end
  end,
})

local function setup_ui_plugins()
  require("config.noice").setup()
  require("config.hardtime").setup()
  require("config.hover").setup()
  require("config.barbecue").setup()
end

-- UI plugins: setup after install/update
autocmd("PackChanged", {
  group = augroup("ui_plugins_install", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= "install" and kind ~= "update" then
      return
    end

    local ui_plugins = {
      ["hardtime.nvim"] = "hardtime.nvim",
      ["barbecue.nvim"] = "barbecue.nvim",
      ["nvim-navic"] = "nvim-navic",
      ["noice.nvim"] = "noice.nvim",
      ["nvim-notify"] = "nvim-notify",
      ["hover.nvim"] = "hover.nvim",
    }

    local pack = ui_plugins[name]
    if not pack then
      return
    end

    if not ev.data.active then
      vim.cmd.packadd(pack)
    end
    setup_ui_plugins()
  end,
})

-- fff.nvim: download binary on install/update
autocmd("PackChanged", {
  group = augroup("fff_install", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "fff.nvim" and (kind == "install" or kind == "update") then
      if not ev.data.active then vim.cmd.packadd("fff.nvim") end
      require("fff.download").download_or_build_binary()
    end
  end,
})
