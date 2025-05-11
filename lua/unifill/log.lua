-- Logging functionality for unifill using plenary.nvim's logger

-- Import plenary logger
local plenary_log = require("plenary.log")

-- Create the logger
local log = plenary_log.new({
    -- Plugin name
    plugin = "unifill",
    
    -- Log level from environment or default to info
    level = vim.env.UNIFILL_LOG_LEVEL or "info",
    
    -- Show in console for debugging
    use_console = "sync",
    
    -- Don't write to log file
    use_file = false,
    
    -- Add highlights to console output
    highlights = true,
})

-- Print a message to indicate the logger is initialized
print("Unifill logger initialized with level: " .. (vim.env.UNIFILL_LOG_LEVEL or "info"))

return log