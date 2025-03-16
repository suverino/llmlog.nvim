-- llmlog.nvim - LLM log management and workflow tools for Neovim
local M = {}

-- Configuration with defaults
M.config = {
  log_dir = "~/Documents/llmlog/",
  split_direction = "topleft vsplit",
  split_size = 0.33,
  delimiter = "--",
  file_extension = ".md"
}

-- Setup function to override defaults
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  end
  return M
end

-- Function to create a new LLM log file
function M.create_log_file()
  -- Get current timestamp
  local timestamp = os.date("%y%m%d-%H%M")

  -- Prompt for log name
  local log_name = vim.fn.input("Enter log name: ")
  if log_name == "" then return end

  -- Create filename
  local filename = string.format("%s%s_%s%s", M.config.log_dir, timestamp, log_name, M.config.file_extension)

  -- Expand home directory
  filename = vim.fn.expand(filename)

  -- Create the directory if it doesn't exist
  vim.fn.mkdir(vim.fn.fnamemodify(filename, ":h"), "p")

  -- Create and open the file in a vertical split on the left
  vim.cmd(M.config.split_direction .. " " .. filename)
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * M.config.split_size))

  -- Add a header to the file
  local header = string.format("# LLM Conversation Log: %s\n\nDate: %s\n\n", log_name, os.date("%Y-%m-%d %H:%M:%S"))
  vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(header, "\n"))

  -- Move cursor to end of file
  vim.cmd("normal G")
end

-- Function to open existing llmlog files
function M.open_existing_log()
  local llmlog_dir = vim.fn.expand(M.config.log_dir)
  
  -- Check if directory exists
  if vim.fn.isdirectory(llmlog_dir) ~= 1 then
    vim.notify("LLM log directory doesn't exist: " .. llmlog_dir, vim.log.levels.ERROR)
    return
  end
  
  -- Get all log files
  local log_files = vim.fn.glob(llmlog_dir .. "*" .. M.config.file_extension, false, true)
  
  if #log_files == 0 then
    vim.notify("No log files found in " .. llmlog_dir, vim.log.levels.WARN)
    return
  end
  
  -- Sort files by modification time (newest first)
  table.sort(log_files, function(a, b) 
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)
  
  -- Format filenames for display in the menu
  local display_options = {}
  for i, file in ipairs(log_files) do
    local filename = vim.fn.fnamemodify(file, ":t")
    local date_part = filename:match("^(%d+%-%d+)") or ""
    local name_part = filename:match("_(.+)" .. M.config.file_extension .. "$") or filename
    display_options[i] = string.format("%s | %s", date_part, name_part)
  end
  
  -- Show selection menu
  vim.ui.select(display_options, {
    prompt = "Select LLM log file to open:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if not choice then return end
    
    -- Open the selected file in a vertical split on the left
    vim.cmd(M.config.split_direction .. " " .. log_files[idx])
    vim.cmd("vertical resize " .. math.floor(vim.o.columns * M.config.split_size))
  end)
end

-- Function to append a delimiter and enter insert mode
function M.append_delimiter()
  -- Move to the end of the file
  vim.cmd('normal! G')

  -- Add an empty line, the delimiter, and another empty line
  local lines_to_append = {'', M.config.delimiter, ''}
  vim.api.nvim_buf_set_lines(0, -1, -1, false, lines_to_append)

  -- Move the cursor to the last line
  vim.cmd('normal! G')

  -- Move to the end of the last line and enter insert mode
  vim.cmd('normal! A')
end

-- LLM workflow - copypastemaxxing functions

-- Copy most recent code block
function M.copy_most_recent_code_block()
  -- Get all lines in the current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Variables to track the code block
  local start_line = -1
  local end_line = -1
  local in_code_block = false

  -- Iterate through lines in reverse order
  for i = #lines, 1, -1 do
    local line = lines[i]

    -- Check for code block delimiters
    if line:match("^```") then
      if in_code_block then
        -- Found the start of the most recent code block
        start_line = i
        break
      else
        -- Found the end of the most recent code block
        end_line = i
        in_code_block = true
      end
    end
  end

  -- If a code block was found
  if start_line ~= -1 and end_line ~= -1 then
    -- Extract the code block (excluding the delimiters)
    local code_block = table.concat(lines, "\n", start_line + 1, end_line - 1)

    -- Copy to system clipboard
    vim.fn.setreg('+', code_block)
    -- Copy to Vim buffer
    vim.fn.setreg('"', code_block)

    -- Notify the user
    vim.notify("Most recent code block copied to clipboard", vim.log.levels.INFO)
  else
    vim.notify("No code block found", vim.log.levels.WARN)
  end
end

-- Copy code block above cursor
function M.copy_code_block_above_cursor()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, cursor_line, false)
  local start_line, end_line = -1, -1

  for i = #lines, 1, -1 do
    if lines[i]:match("^```") then
      if end_line == -1 then
        end_line = i
      else
        start_line = i
        break
      end
    end
  end

  if start_line ~= -1 and end_line ~= -1 then
    local code_block = table.concat(lines, "\n", start_line + 1, end_line - 1)
    vim.fn.setreg('+', code_block)
    vim.fn.setreg('"', code_block)
    vim.notify("Code block above cursor copied to clipboard", vim.log.levels.INFO)
  else
    vim.notify("No code block found above cursor", vim.log.levels.WARN)
  end
end

-- Copy code block below cursor
function M.copy_code_block_below_cursor()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, cursor_line - 1, -1, false)
  local start_line, end_line = -1, -1

  for i, line in ipairs(lines) do
    if line:match("^```") then
      if start_line == -1 then
        start_line = i
      else
        end_line = i
        break
      end
    end
  end

  if start_line ~= -1 and end_line ~= -1 then
    local code_block = table.concat(lines, "\n", start_line + 1, end_line - 1)
    vim.fn.setreg('+', code_block)
    vim.fn.setreg('"', code_block)
    vim.notify("Code block below cursor copied to clipboard", vim.log.levels.INFO)
  else
    vim.notify("No code block found below cursor", vim.log.levels.WARN)
  end
end

-- Copy code block surrounding cursor
function M.copy_code_block_surrounding_cursor()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local start_line, end_line = -1, -1

  -- Search upwards for start of code block
  for i = cursor_line, 1, -1 do
    if lines[i]:match("^```") then
      start_line = i
      break
    end
  end

  -- Search downwards for end of code block
  for i = cursor_line, #lines do
    if lines[i]:match("^```") then
      end_line = i
      break
    end
  end

  if start_line ~= -1 and end_line ~= -1 and start_line < end_line then
    local code_block = table.concat(lines, "\n", start_line + 1, end_line - 1)
    vim.fn.setreg('+', code_block)
    vim.fn.setreg('"', code_block)
    vim.notify("Code block surrounding cursor copied to clipboard", vim.log.levels.INFO)
  else
    vim.notify("No code block found surrounding cursor", vim.log.levels.WARN)
  end
end

-- Copy entire file to clipboard
function M.copy_entire_file()
  vim.cmd('w !xclip -selection clipboard')
  vim.notify("Entire file copied to clipboard", vim.log.levels.INFO)
end

-- Replace entire file with clipboard contents
function M.replace_with_clipboard()
  vim.cmd('ggdG"+P')
  vim.notify("File replaced with clipboard contents", vim.log.levels.INFO)
end

-- Function to setup keymaps
function M.setup_keymaps()
  -- LLM log management
  vim.api.nvim_set_keymap('n', '<leader>ll', ':lua require("llmlog").create_log_file()<CR>', 
    { noremap = true, silent = true, desc = 'Create LLM log file in vertical split' })
  
  vim.api.nvim_set_keymap('n', '<leader>lo', ':lua require("llmlog").open_existing_log()<CR>', 
    { noremap = true, silent = true, desc = 'Open existing LLM log file' })
  
  -- Key mapping to append delimiter and enter insert mode, only in Markdown files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      vim.api.nvim_buf_set_keymap(0, 'n', '<leader>n', ':lua require("llmlog").append_delimiter()<CR>', 
        { noremap = true, silent = true, desc = 'Append delimiter and enter insert mode' })
    end
  })
  
  -- Copypastemaxxing
  vim.api.nvim_set_keymap('n', '<leader>cp', ':lua require("llmlog").copy_entire_file()<CR>', 
    { noremap = true, silent = true, desc = 'Copy entire file' })
  
  vim.api.nvim_set_keymap('n', '<leader>rp', ':lua require("llmlog").replace_with_clipboard()<CR>', 
    { noremap = true, silent = true, desc = 'Paste clipboard to replace entire file' })
  
  vim.api.nvim_set_keymap('n', '<leader>cc', ':lua require("llmlog").copy_most_recent_code_block()<CR>', 
    { noremap = true, silent = true, desc = 'Copy most recent code block' })
  
  vim.api.nvim_set_keymap('n', '<leader>ca', ':lua require("llmlog").copy_code_block_above_cursor()<CR>', 
    { noremap = true, silent = true, desc = 'Copy code block above cursor' })
  
  vim.api.nvim_set_keymap('n', '<leader>cb', ':lua require("llmlog").copy_code_block_below_cursor()<CR>', 
    { noremap = true, silent = true, desc = 'Copy code block below cursor' })
  
  vim.api.nvim_set_keymap('n', '<leader>cs', ':lua require("llmlog").copy_code_block_surrounding_cursor()<CR>', 
    { noremap = true, silent = true, desc = 'Copy code block surrounding cursor' })
end

return M
