return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("noice").setup({
      messages = {
        enabled = true,
        view = "notify",
        view_error = "notify",
        view_warn = "notify",
        view_history = "messages",
        view_search = "virtualtext",
      },
      notify = {
        enabled = true,
        view = "notify",
      },
      views = {
        -- Errors like `:Noice` (command not found etc.) often render via mini/messages views.
        mini = {
          win_options = {
            winblend = 0,
            winhighlight = "Normal:NoiceMini,FloatBorder:FloatBorder",
          },
        },
        popupmenu = {
          win_options = {
            winblend = 0,
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
        notify = {
          win_options = {
            winblend = 0,
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
        popup = {
          win_options = {
            winblend = 0,
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
        cmdline_popup = {
          win_options = {
            winblend = 0,
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
        cmdline_popupmenu = {
          win_options = {
            winblend = 0,
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    })
  end,
}

