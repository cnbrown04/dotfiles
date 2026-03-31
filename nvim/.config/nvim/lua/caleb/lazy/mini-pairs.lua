return {
  "echasnovski/mini.nvim",
  version = "*",
  config = function()
    require("mini.pairs").setup()
    pcall(function()
      require("mini.icons").setup()
    end)
  end,
}

