return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "biomejs", "oxlint" },
      javascriptreact = { "biomejs", "oxlint" },
      typescript = { "biomejs", "oxlint" },
      typescriptreact = { "biomejs", "oxlint" },
      json = { "biomejs" },
      jsonc = { "biomejs" },
    }

    local function lint_if_available()
      local names = lint.linters_by_ft[vim.bo.filetype] or {}
      if type(names) == "string" then
        names = { names }
      end

      local available = {}
      for _, name in ipairs(names) do
        local linter = lint.linters[name]
        if type(linter) == "function" then
          linter = linter()
        end
        local cmd = linter and linter.cmd
        if type(cmd) == "function" then
          cmd = cmd()
        end
        if type(cmd) == "string" and vim.fn.executable(cmd) == 1 then
          table.insert(available, name)
        end
      end

      if #available > 0 then
        lint.try_lint(available)
      end
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("caleb-lint", { clear = true }),
      callback = lint_if_available,
    })
  end,
}

