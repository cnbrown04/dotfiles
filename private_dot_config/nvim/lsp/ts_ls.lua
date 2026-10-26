---@type vim.lsp.Config
return {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_markers = {
		"tsconfig.json",
		"jsconfig.json",
		"package.json",
		".git",
	},
	init_options = {
		hostInfo = "neovim",
		-- Global TypeScript (npm -g) for files outside a project with its own.
		tsserver = { fallbackPath = vim.fn.expand("~/.local/lib/node_modules/typescript/lib") },
	},
}
