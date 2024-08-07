# vial.nvim

<img src="assets/logo.png" alt="Vial Logo" width="60" height="120" align="right"/>

vial.nvim is a Neovim plugin that triggers commands on a separate terminal, primarily designed for running unit tests.

It provides an efficient workflow for developers by automatically running tests on file save and offering various test-related commands.

## Features

https://github.com/fcoury/vial.nvim/assets/1371/c50fd29c-daa5-47a3-bee1-3e8c554eb40d

- Automatically runs tests on file save
- Runs the current test if a test is detected under cursor or repeats last test execution
- Customizable for different file types and test commands
- Toggleable automatic test running
- Easy-to-use keybindings for various test-related actions

## Installation

### Executable

Download the `vial` executable from the [Latest Release](https://github.com/fcoury/vial.nvim/releases/latest).

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'fcoury/vial.nvim',
  config = function()
    require('vial').setup({
      -- your configuration here
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'fcoury/vial.nvim',
  config = function()
    require('vial').setup({
      -- your configuration here
    })
  end
}
```

## Configuration

### `setup` Function

The `setup` function accepts the following options:

- `vial_path` (string): Path to the `vial` executable.
- `file_types` (table): Configuration for different file types. Each key is a file type, and the value is a table with the following keys:
  - `command` (string): Command to run, where `%s` will be replaced by the test name.
  - `extensions` (table): List of file extensions for the file type.
  - `extract` (function): Function to extract the test name from the current buffer.

Here's an example configuration for Rust files using lsp-config and falling back to regex:

```lua
local function get_params()
	local params = vim.lsp.util.make_position_params()
	params.textDocument = vim.lsp.util.make_text_document_params()
	return params
end

local function get_current_test_args()
	local params = get_params()
	local result = vim.lsp.buf_request_sync(0, "experimental/runnables", params, 1000)
	if result and result[1] and result[1].result then
		for _, runnable in ipairs(result[1].result) do
			if runnable.kind == "cargo" and runnable.args.executableArgs then
				local args = runnable.args.executableArgs
				-- Check if this is a specific test
				if #args >= 1 and args[1]:match("^[%w_:]+::[%w_]+$") and runnable.label:match("^test ") then
					return runnable.args
				end
			end
		end
	end
	return nil
end

local function current_test_name_regex()
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

local function current_rust_test_name()
	local cmd
	if pcall(require, "lspconfig") then
		local args = get_current_test_args()
		if args == nil then
			return nil
		end
		cmd = table.concat(args.cargoArgs, " ") .. " -- " .. table.concat(args.executableArgs, " ")
	else
		local test_name = current_test_name_regex()
		if test_name == nil then
			return nil
		end
		cmd = "test %s -- --nocapture --color=always"
	end

	return cmd
end

return {
	"fcoury/vial.nvim",
	dir = "~/code/vial",
	config = function()
		require("vial").setup({
			vial_path = "/Users/fcoury/code/vial/target/debug/vial",

			file_types = {
				rust = {
					command = "cargo %s",
					extensions = { ".rs" },
					extract = current_rust_test_name,
				},
			},
		})
	end,
}
```

Adjust the `vial_path` to point to your vial executable.

## Usage

Start the vial server with the `vial server` command on the terminal you want to use for running your commands.

vial.nvim provides the following keybindings by default:

- `<leader>tt`: Run the current test
- `<leader>tl`: Run the last test
- `<leader>tc`: Clear the last test
- `<leader>ta`: Toggle automatic test running
- `<leader>ts`: Show the last test name

## Functions

- `require('vial').run_test()`: Run the current test
- `require('vial').run_last_test()`: Run the last test
- `require('vial').clear_last_test()`: Clear the last test
- `require('vial').toggle_active()`: Toggle automatic test running
- `require('vial').show_last_test()`: Display the name of the last test

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
