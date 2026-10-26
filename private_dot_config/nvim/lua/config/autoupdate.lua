local M = {}

-- Update all vim.pack plugins at most once a day, shortly after startup.
local interval = 24 * 60 * 60
local stamp = vim.fn.stdpath("state") .. "/pack-last-update"

local function last_update()
	local f = io.open(stamp, "r")
	if not f then
		return 0
	end
	local t = tonumber(f:read("*l")) or 0
	f:close()
	return t
end

local function mark_updated()
	local f = io.open(stamp, "w")
	if f then
		f:write(tostring(os.time()))
		f:close()
	end
end

function M.setup()
	if os.time() - last_update() < interval then
		return
	end

	vim.api.nvim_create_autocmd("VimEnter", {
		group = vim.api.nvim_create_augroup("pack_autoupdate", { clear = true }),
		once = true,
		callback = function()
			vim.defer_fn(function()
				mark_updated()
				vim.pack.update(nil, { force = true })
			end, 1000)
		end,
	})
end

return M
