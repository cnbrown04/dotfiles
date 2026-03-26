return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    config = function()
        -- You need a keybinding to actually see it!
        vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = "Toggle Neo-tree" })

        require('neo-tree').setup({
            close_if_last_window = true,
            filesystem = {
                use_libuv_file_watcher = true,
                filtered_items = {
                    visible = true, -- shows hidden files by default
                }
            }
        })
    end
}
