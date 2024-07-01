# Vial.nvim

`vial.nvim` is a Neovim plugin designed to run Rust tests using a configurable `vial` executable. This plugin allows you to run the current test under the cursor or the last run test with simple key mappings.

## Features

- Run the Rust test at the current cursor position.
- Re-run the last executed test.
- Configurable path for the `vial` executable.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following to your Neovim configuration:

```lua
require('lazy').setup({
    -- Add other plugins here
    {
        'fcoury/vial.nvim',
        config = function()
            require('vial').setup({ vial_path = "/path/to/vial" })
        end
    }
})
```

Replace `/path/to/vial` with the actual path to your `vial` executable.

## Configuration

### Default Configuration

By default, the plugin looks for the `vial` executable at `target/release/vial`. If your `vial` executable is located elsewhere, you can configure the path during setup:

```lua
require('vial').setup({
    vial_path = "/custom/path/to/vial"  -- Replace with your actual path
})
```

### Key Mappings

The plugin provides the following default key mappings:

- `<leader>tt`: Run the test at the current cursor position.
- `<leader>tl`: Run the last executed test.

You can add these mappings to your Neovim configuration file:

```lua
vim.api.nvim_set_keymap("n", "<leader>tt", "<cmd>lua require'vial'.run_test()<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>tl", "<cmd>lua require'vial'.run_last_test()<cr>", { noremap = true, silent = true })
```

## Usage

1. Place the cursor on the line containing the test function you want to run.
2. Press `<leader>tt` to run the test.
3. To re-run the last executed test, press `<leader>tl`.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This plugin is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Neovim](https://neovim.io/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
