---@brief [[
--- Logging functionality for unifill using plenary.nvim's logger
---
--- This module provides logging capabilities for the unifill plugin using
--- plenary.nvim's logger. It supports different log levels (debug, info, warn, error)
--- and can write logs to both the console and a log file.
---
--- The log level can be configured using the UNIFILL_LOG_LEVEL environment variable.
--- Default log level is "info" if not specified.
---
--- Usage:
---   local log = require("unifill.log")
---   log.debug("Debug message")
---   log.info("Info message")
---   log.warn("Warning message")
---   log.error("Error message")
---@brief ]]

-- Import plenary logger and path utilities
local plenary_log = require("plenary.log")
local Path = require("plenary.path")

-- Set up log directory
local root_dir = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('%:p')), ':h:h:h')
local log_dir = Path:new(root_dir, 'tmp', 'logs')
local log_path = log_dir:joinpath('unifill.log').filename

-- Create log directory if it doesn't exist
log_dir:mkdir({ parents = true })

-- Clear the log file before initializing the logger
local f = io.open(log_path, "w")
if f then
    f:write("Unifill log started at " .. os.date() .. "\n")
    f:close()
end

-- Print log location for easy reference
vim.api.nvim_echo({{"Unifill logs at: " .. log_path, "Normal"}}, true, {})

-- Create the logger
local log = plenary_log.new({
    -- Plugin name
    plugin = "unifill",
    
    -- Log level from environment or default to info
    level = vim.env.UNIFILL_LOG_LEVEL or "info",
    
    -- Show in console for debugging (can be true, false, or "sync")
    use_console = true,
    
    -- Write to log file
    use_file = true,
    
    -- Specify our log file path (use outfile, not filename)
    outfile = log_path,
    
    -- Add highlights to console output
    highlights = true,
})

return log