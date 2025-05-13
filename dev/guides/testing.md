# Comprehensive Guide to Testing Neovim Plugins with Telescope Integration

This guide provides a step-by-step approach to setting up a robust testing
environment for Neovim plugins that integrate with Telescope, with a focus on
using Plenary's test framework, Lazy for plugin management, and techniques for
simulating user interactions.

## 1. Setting Up a Plenary Test Suite with Lazy Plugin Manager

### 1.1 Create a Minimal Init File

First, create a `spec/test_init.lua` file that will bootstrap your test
environment:

```lua
-- spec/test_init.lua
-- Set environment variables for testing
vim.env.PLENARY_TEST = "1"
vim.env.LOG_LEVEL = "error"  -- Minimize logging during tests

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Create logs directory
local log_dir = vim.fn.stdpath('cache') .. '/logs'
vim.fn.mkdir(log_dir, 'p')

-- Add the project directory to runtimepath
local project_root = vim.fn.getcwd()
vim.opt.runtimepath:append(project_root)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

-- Configure lazy.nvim with your plugin and its dependencies
require("lazy").setup({
  -- Your plugin (local)
  {
    dir = project_root,
    name = "your-plugin-name",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
      -- Add other dependencies as needed
    },
    config = function()
      -- Configure your plugin for testing
      require('your-plugin').setup({
        -- Test configuration
      })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require('telescope').setup({
        defaults = {
          -- Telescope configuration for testing
          layout_strategy = "horizontal",
          layout_config = {
            width = 0.8,
            height = 0.8,
          },
        },
      })
    end,
  },
})

-- Load plenary for testing
require('plenary.busted')

-- Clear any cached modules to ensure clean test environment
package.loaded['your-plugin'] = nil
-- Clear other relevant modules
```

### 1.2 Create a Test Runner Script

Create a shell script to run your tests:

```bash
#!/usr/bin/env bash
# bin/run-tests

set -e

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create necessary directories
mkdir -p "$PROJECT_ROOT/tmp/logs"

# Use the test init file
INIT_LUA="$PROJECT_ROOT/spec/test_init.lua"

# Run the tests with the test_init.lua
echo "Running tests with Telescope integration..."
nvim --headless -u "$INIT_LUA" -c "PlenaryBustedDirectory spec/ { minimal_init = '$INIT_LUA' }"
```

Make the script executable:

```bash
chmod +x bin/run-tests
```

### 1.3 Testing Your Setup

Create a simple test file to verify your setup:

```lua
-- spec/plugin_setup_spec.lua
describe("plugin setup", function()
  it("loads the plugin", function()
    local plugin = require("your-plugin")
    assert.is_not_nil(plugin)
  end)

  it("loads telescope", function()
    local telescope = require("telescope")
    assert.is_not_nil(telescope)
  end)
end)
```

Run the test:

```bash
./bin/run-tests
```

If successful, you should see output indicating that the tests passed.

## 2. Testing Neovim Operations

### 2.1 Buffer Manipulation

```lua
describe("buffer operations", function()
  local buffer

  before_each(function()
    -- Create a fresh buffer for each test
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
  end)

  after_each(function()
    -- Clean up after each test
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  it("can set and get buffer lines", function()
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"line 1", "line 2", "line 3"})

    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

    -- Verify content
    assert.are.same({"line 1", "line 2", "line 3"}, lines)
  end)

  it("can get buffer content after operations", function()
    -- Set initial content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"initial content"})

    -- Perform an operation (e.g., through your plugin)
    -- require("your-plugin").some_function()

    -- Get the resulting content
    local result = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

    -- Verify the expected result
    -- assert.are.same({"expected content"}, result)
  end)
end)
```

### 2.2 Command Mode Execution

```lua
describe("command mode operations", function()
  it("can execute commands", function()
    -- Execute a Vim command
    vim.cmd("set number")

    -- Verify the result
    assert.is_true(vim.opt.number:get())
  end)

  it("can execute plugin commands", function()
    -- Execute a command provided by your plugin
    -- vim.cmd("YourPluginCommand")

    -- Verify the expected state
    -- assert.is_true(some_condition)
  end)
end)
```

### 2.3 Keypress Simulation

```lua
describe("keypress simulation", function()
  local buffer

  before_each(function()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {""})
  end)

  it("can simulate insert mode keypresses", function()
    -- Enter insert mode and type text
    local keys = vim.api.nvim_replace_termcodes("iHello, world!<Esc>", true, false, true)
    vim.api.nvim_feedkeys(keys, "tx", false)

    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

    -- Verify content
    assert.are.same({"Hello, world!"}, lines)
  end)

  it("can simulate normal mode keypresses", function()
    -- Set up buffer with content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"line 1", "line 2", "line 3"})

    -- Move to line 2 and delete it
    local keys = vim.api.nvim_replace_termcodes("2Gdd", true, false, true)
    vim.api.nvim_feedkeys(keys, "tx", false)

    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

    -- Verify content
    assert.are.same({"line 1", "line 3"}, lines)
  end)

  it("can handle complex key sequences", function()
    -- Set up buffer with content
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {"test line"})

    -- Complex sequence: go to end of line, enter insert mode, add text, exit
    local keys = vim.api.nvim_replace_termcodes("A - appended<Esc>", true, false, true)
    vim.api.nvim_feedkeys(keys, "tx", false)

    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

    -- Verify content
    assert.are.same({"test line - appended"}, lines)
  end)
end)
```

### 2.4 Handling Asynchronous Operations

```lua
describe("async operations", function()
  it("can wait for async operations to complete", function()
    local async_completed = false

    -- Simulate an async operation
    vim.defer_fn(function()
      async_completed = true
    end, 100)

    -- Wait for the operation to complete (with timeout)
    vim.wait(1000, function()
      return async_completed
    end, 10)

    -- Verify the operation completed
    assert.is_true(async_completed)
  end)
end)
```

## 3. Testing Telescope UI Integration

### 3.1 Basic Telescope Picker Testing

```lua
describe("telescope integration", function()
  it("can create a telescope picker", function()
    -- Require telescope modules
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    -- Create a basic picker
    local picker = pickers.new({}, {
      prompt_title = "Test Picker",
      finder = finders.new_table({
        results = {"item1", "item2", "item3"}
      }),
      sorter = conf.generic_sorter({}),
    })

    -- Verify the picker was created
    assert.is_not_nil(picker)
  end)

  it("can access your plugin's telescope extension", function()
    -- Require your plugin's telescope module
    local plugin_telescope = require("your-plugin.telescope")

    -- Verify it exists
    assert.is_not_nil(plugin_telescope)

    -- If your plugin registers a telescope extension, verify it
    local telescope = require("telescope")
    telescope.setup()
    telescope.load_extension("your_extension_name")

    -- Verify the extension was loaded
    assert.is_not_nil(telescope.extensions.your_extension_name)
  end)
end)
```

### 3.2 Simulating Telescope UI Interaction

```lua
describe("telescope ui interaction", function()
  -- This test requires a running Neovim instance
  it("can simulate interaction with telescope UI", function()
    -- Open a telescope picker from your plugin
    -- This could be a command or function call
    -- require("your-plugin").open_picker()

    -- Wait for the picker to open
    vim.wait(1000, function()
      -- Check if the telescope prompt buffer exists
      local buffers = vim.api.nvim_list_bufs()
      for _, buf in ipairs(buffers) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name:match("telescope") then
          return true
        end
      end
      return false
    end, 10)

    -- Type into the prompt
    local keys = vim.api.nvim_replace_termcodes("search term<CR>", true, false, true)
    vim.api.nvim_feedkeys(keys, "tx", false)

    -- Wait for results to update
    vim.wait(500, function() return true end)

    -- Navigate to a result (e.g., first item)
    keys = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
    vim.api.nvim_feedkeys(keys, "tx", false)

    -- Wait for selection to be processed
    vim.wait(500, function() return true end)

    -- Verify the expected outcome
    -- This depends on what your picker does with selections
    -- assert.is_true(some_condition)
  end)
end)
```

### 3.3 Testing Telescope Actions

```lua
describe("telescope actions", function()
  it("can test telescope actions directly", function()
    -- Create a mock selection
    local selection = {
      value = "test value",
      display = "Test Display",
      ordinal = "test",
    }

    -- Create a mock picker state
    local picker = {
      close = function() end,
      selection = selection,
    }

    -- Mock the actions.state module
    local actions_state = {
      get_selected_entry = function()
        return selection
      end
    }

    -- Store the original module
    local original_actions_state = package.loaded["telescope.actions.state"]

    -- Replace with our mock
    package.loaded["telescope.actions.state"] = actions_state

    -- Call your plugin's action function
    -- local result = require("your-plugin.telescope").action_function(picker)

    -- Verify the result
    -- assert.is_equal("expected result", result)

    -- Restore the original module
    package.loaded["telescope.actions.state"] = original_actions_state
  end)
end)
```

## 4. Verifying Test Results

### 4.1 Testing Plugin Functionality

```lua
describe("plugin functionality", function()
  it("performs its core function correctly", function()
    -- Set up test conditions
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)

    -- Call your plugin's function
    -- local result = require("your-plugin").main_function()

    -- Verify the result
    -- assert.is_equal("expected result", result)

    -- Or verify buffer state
    -- local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    -- assert.are.same({"expected content"}, lines)
  end)
end)
```

### 4.2 Testing Error Handling

```lua
describe("error handling", function()
  it("handles invalid input gracefully", function()
    -- Test with invalid input
    local status, err = pcall(function()
      -- require("your-plugin").function_with_validation(invalid_input)
    end)

    -- Verify error handling
    assert.is_false(status)
    -- assert.matches("expected error message", err)
  end)
end)
```

### 4.3 Testing Configuration Options

```lua
describe("configuration options", function()
  after_each(function()
    -- Reset to default configuration
    -- require("your-plugin").setup({})
  end)

  it("respects custom configuration", function()
    -- Set custom configuration
    -- require("your-plugin").setup({
    --   custom_option = "value"
    -- })

    -- Verify the configuration was applied
    -- local config = require("your-plugin.config").get()
    -- assert.is_equal("value", config.custom_option)
  end)
end)
```

## 5. Troubleshooting Common Issues

### 5.1 Debugging Test Failures

When tests fail, add debug output to help identify the issue:

```lua
-- Add debug output
print("Debug: " .. vim.inspect(some_variable))

-- For more persistent logging
local log_file = io.open(vim.fn.stdpath('cache') .. '/test_log.txt', 'a')
log_file:write("Debug: " .. vim.inspect(some_variable) .. "\n")
log_file:close()
```

### 5.2 Handling Timing Issues

If tests fail due to timing issues:

```lua
-- Increase wait time for async operations
vim.wait(2000, function()
  return condition_met
end, 50)  -- Check every 50ms, wait up to 2 seconds

-- Add a fixed delay if needed
vim.cmd("sleep 100m")  -- Sleep for 100 milliseconds
```

### 5.3 Isolating Test Environment

Ensure tests don't interfere with each other:

```lua
-- In before_each
vim.cmd('silent! %bwipeout!')  -- Clear all buffers
vim.cmd('silent! tabonly')     -- Close all tabs except current
```
