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

-- Set up log directory using XDG standards
local function get_xdg_cache_home()
    local xdg_cache = os.getenv("XDG_CACHE_HOME")
    if xdg_cache then
        return xdg_cache
    else
        return vim.fn.expand("~/.cache")
    end
end

local log_dir = Path:new(get_xdg_cache_home(), 'unifill', 'logs')
local log_path = log_dir:joinpath('unifill.log').filename

-- Create log directory if it doesn't exist
local ok, err = pcall(function()
    log_dir:mkdir({ parents = true })
end)

if not ok then
    -- Fall back to a temporary directory if we can't create the XDG directory
    local tmp_dir = vim.fn.tempname():match("(.*)/[^/]*$")
    log_dir = Path:new(tmp_dir, 'unifill', 'logs')
    log_path = log_dir:joinpath('unifill.log').filename
    log_dir:mkdir({ parents = true })
    vim.notify("Could not create XDG cache directory. Falling back to: " .. log_path, vim.log.levels.WARN)
end

-- Clear the log file before initializing the logger
local f = io.open(log_path, "w")
if f then
    f:write("Unifill log started at " .. os.date() .. "\n")
    f:close()
end

-- Log location is available but not printed on startup
-- vim.api.nvim_echo({{"Unifill logs at: " .. log_path, "Normal"}}, true, {})

-- Create the logger
local log = plenary_log.new({
    -- Plugin name
    plugin = "unifill",
    
    -- Log level from environment or default to info
    level = vim.env.UNIFILL_LOG_LEVEL or "info",
    
    -- Show in console for debugging (can be true, false, or "sync")
    -- Default to false to avoid cluttering the UI
    use_console = false,
    
    -- Write to log file
    use_file = true,
    
    -- Specify our log file path (use outfile, not filename)
    outfile = log_path,
    
    -- Add highlights to console output
        highlights = true,
    })
    
    -- Export log path for testing
    log._log_path = log_path
    
    return log