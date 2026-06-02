local M = {}

local servers = {
	"lua_ls",
	"rust_analyzer",
	"ts_ls",
	"pyright",
	"html",
	"cssls",
}

local function on_attach(client, bufnr)
	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
	end

	map("n", "gd", vim.lsp.buf.definition, "Go to definition")
	map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
	map("n", "gr", vim.lsp.buf.references, "References")
	map("n", "gi", vim.lsp.buf.implementation, "Implementation")
	map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
	map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
	map("n", "<leader>cf", function()
		vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 3000 })
	end, "Format buffer")

	if client:supports_method("textDocument/completion") then
		vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
	end
end

local function setup_lua_ls()
	vim.lsp.config("lua_ls", {
		on_init = function(client)
			if client.workspace_folders then
				local path = client.workspace_folders[1].name
				if
					path ~= vim.fn.stdpath("config")
					and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
				then
					return
				end
			end

			client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
				runtime = {
					version = "LuaJIT",
					path = { "lua/?.lua", "lua/?/init.lua" },
				},
				workspace = {
					checkThirdParty = false,
					library = { vim.env.VIMRUNTIME },
				},
			})
		end,
	})
end

function M.setup()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true

	vim.lsp.config("*", {
		capabilities = capabilities,
		root_markers = { ".git", ".hg", ".svn" },
		on_attach = on_attach,
	})

	setup_lua_ls()
	vim.lsp.enable(servers)
end

return M
