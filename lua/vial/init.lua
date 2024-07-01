local M = {}
local last_test = nil
local vial_path = "vial"

function M.setup(opts)
	opts = opts or {}
	vial_path = opts.vial_path or vial_path
end

local function current_test_name()
	-- Get the current buffer and cursor position
	local bufnr = vim.api.nvim_get_current_buf()
	---@diagnostic disable-next-line: deprecated
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

	local function_declaration_line = 0
	local function_name = ""

	-- Check lines above the cursor for the #[test] attribute and function definition
	for i = row, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]

		-- Check for function start and capture the function name
		if line:match("^%s*fn%s") then
			function_declaration_line = i
			function_name = line:match("^%s*fn%s([%w_]+)%s*%(")
			break
		end
	end

	for i = function_declaration_line, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
		if line:match("^%s*#%[test%]") then
			return function_name
		end
	end

	return nil
end

-- Function to get the current context and run command
local function run_command(command)
	-- local file = vim.api.nvim_buf_get_name(0)
	-- local line = vim.fn.line(".")
	-- local context_command = string.format("%s -file=%s -line=%s", command, file, line)

	-- Execute the Rust binary and pass the command
	local handle = io.popen(string.format("%s send '%s' > /dev/null 2>&1", vial_path, command))
	local result = handle:read("*a")
	handle:close()

	print(result)
end

local function run_test(test_name)
	local cmd = "cargo test -- " .. test_name .. " --nocapture --color=always"
	run_command(cmd)
end

function M.run_test()
	local test_name = current_test_name()

	if test_name == nil then
		print("No test found")
		return
	end

	last_test = test_name
	run_test(test_name)
end

function M.run_last_test()
	if last_test == nil then
		print("No last test found")
		return
	end

	run_test(last_test)
end

vim.api.nvim_set_keymap("n", "<leader>tt", "<cmd>lua require'vial'.run_test()<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap(
	"n",
	"<leader>tl",
	"<cmd>lua require'vial'.run_last_test()<cr>",
	{ noremap = true, silent = true }
)

return M
