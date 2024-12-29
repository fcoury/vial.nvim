local M = {}
local vial_path = nil
local file_types = nil
local enabled = false
local uv = vim.loop

function M.setup(opts)
	opts = opts or {}
	vial_path = opts.vial_path or vial_path
	file_types = opts.file_types
	enabled = true

	vim.cmd([[autocmd BufWritePost * lua require'vial'.on_buf_write_post()]])
end

-- Function to get the current context and run command
local function run_command(command)
	local stdin = assert(uv.new_pipe())
	local stdout = assert(uv.new_pipe())
	local stderr = assert(uv.new_pipe())

	local handle, pid = uv.spawn(vial_path, {
		args = { "send", command },
		stdio = { stdin, stdout, stderr },
	}, function(code, signal) -- on exit
		stdin:close()
		stdout:close()
		stderr:close()
	end)

	if not handle then
		error(string.format("Failed to spawn process: %s", pid))
	end
end

-- old sync way
-- -- Function to get the current context and run command
-- local function run_command(command)
-- 	local handle = io.popen(string.format("%s send '%s' > /dev/null 2>&1", vial_path, command))
--
-- 	-- we don't handle responses yet
-- 	-- local result = handle:read("*a")
-- 	-- handle:close()
-- end

local function current_settings()
	if file_types == nil then
		print("No file types defined")
		return
	end

	local filetype = vim.bo.filetype
	return file_types[filetype]
end

local function get(setting)
	local settings = current_settings()
	if settings == nil then
		return nil
	end

	return settings[setting]
end

local function set(setting, value)
	local settings = current_settings()
	if settings == nil then
		return
	end

	settings[setting] = value
end

local function run_test(test_name)
	local raw_cmd = get("command")
	if raw_cmd == nil then
		print("No command defined")
		return
	end

	local cmd = string.format(raw_cmd, test_name)
	run_command(cmd)
end

function M.run_test()
	local extract = get("extract")
	if extract == nil then
		return
	end

	local test_name = extract()

	if test_name == nil then
		print("No test found")
		return
	end

	set("last_test", test_name)
	run_test(test_name)
end

function M.run_last_test()
	local last_test = get("last_test")

	if last_test == nil then
		return
	end

	run_test(last_test)
end

local function is_inside_test()
	local extract_fn = get("extract")

	if extract_fn == nil then
		return false
	end

	return get("extract")() ~= nil
end

local function run_last_or_current_test()
	if is_inside_test() then
		M.run_test()
	else
		M.run_last_test()
	end
end

local function on_buf_write_post()
	run_last_or_current_test()
end

function M.toggle_active()
	if enabled then
		vim.cmd([[autocmd BufWritePost * lua require'vial'.on_buf_write_post()]])
		enabled = false
	else
		vim.cmd([[autocmd BufWritePost * lua require'vial'.on_buf_write_post()]])
		enabled = true
	end
end

function M.clear_last_test()
	set("last_test", nil)
end

function M.show_last_test()
	local last_test = get("last_test")

	if last_test == nil then
		print("No last test found")
		return
	end

	print(last_test)
end

vim.api.nvim_set_keymap(
	"n",
	"<leader>tt",
	"<cmd>lua require'vial'.run_test()<cr>",
	{ noremap = true, silent = true, desc = "Run test under cursor with vial" }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>tl",
	"<cmd>lua require'vial'.run_last_test()<cr>",
	{ noremap = true, silent = true, desc = "Re-run last test with vial" }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>tc",
	"<cmd>lua require'vial'.clear_last_test()<cr>",
	{ noremap = true, silent = true, desc = "Clear last vial test" }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>ta",
	"<cmd>lua require'vial'.toggle_active()<cr>",
	{ noremap = true, silent = true, desc = "Enable/disable vial" }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>ts",
	"<cmd>lua require'vial'.show_last_test()<cr>",
	{ noremap = true, silent = true, desc = "Show last test executed by vail" }
)

function M.on_buf_write_post()
	on_buf_write_post()
end

return M
