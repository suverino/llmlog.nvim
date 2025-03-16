# llmlog.nvim

A Neovim plugin for managing LLM conversation logs and enhancing your LLM workflow.

## Features

- **Log Management**
  - Create timestamped LLM log files in Markdown format
  - Open existing logs from a menu
  - Add conversation delimiters with a single keypress

- **LLM Workflow Tools**
  - Copy entire file to clipboard
  - Replace entire file with clipboard contents
  - Copy code blocks (most recent, above cursor, below cursor, surrounding cursor)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "suverino/llmlog.nvim", -- Replace with your GitHub username
  config = function()
    require("llmlog").setup({
      -- Optional configuration
    })
    require("llmlog").setup_keymaps()
  end,
}
```

## Configuration

The default configuration:

```lua
require("llmlog").setup({
  log_dir = "~/Documents/llmlog/",        -- Directory to store logs
  split_direction = "topleft vsplit", -- Split command
  split_size = 0.33,                  -- Split size (fraction of window)
  delimiter = "--",                   -- Delimiter text
  file_extension = ".md"              -- File extension for logs
})
```

## Usage

Default keymaps (requires calling `setup_keymaps()`):

### Log Management
- `<leader>ll` - Create a new LLM log file
- `<leader>lo` - Open an existing LLM log file
- `<leader>n` - Add a delimiter in Markdown files and enter insert mode

### LLM Workflow (Copypastemaxxing)
- `<leader>cp` - Copy entire file to clipboard
- `<leader>rp` - Paste clipboard to replace entire file
- `<leader>cc` - Copy most recent code block
- `<leader>ca` - Copy code block above cursor
- `<leader>cb` - Copy code block below cursor
- `<leader>cs` - Copy code block surrounding cursor
