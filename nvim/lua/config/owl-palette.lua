-- Light Owl (VS Code) — static palette for UI highlights
local M = {
	bg = "#FBFBFB",
	fg = "#403f53",
	status_bg = "#FFFFFF",
	blue = "#4876d6",
	title = "#4876d6",
	cursor = "#4876d6",
	red = "#E64D49",
	green = "#08916a",
	yellow = "#E0AF02",
	cyan = "#0c969b",
	overlay_0 = "#93A1A1",
	overlay_1 = "#5f7e97",
	border = "#d9d9d9",
	sign_change = "#6fbef6",
	error = "#E64D49",
}

function M.strip_alpha(hex)
	if type(hex) ~= "string" then
		return nil
	end
	hex = hex:lower():gsub("^#", "")
	if #hex >= 6 then
		return "#" .. hex:sub(1, 6)
	end
	return nil
end

return M
