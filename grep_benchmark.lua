-- Benchmark script for the grep backend
-- This script measures the performance of the grep backend

-- Set log level to INFO to see benchmark results
vim.env.UNIFILL_LOG_LEVEL = "info"

-- Create a log file
local log_file = io.open("grep_benchmark_results.txt", "w")
if not log_file then
    print("Error: Could not create grep_benchmark_results.txt")
    return
end

-- Helper function to write to log file
local function log(msg)
    print(msg)
    log_file:write(msg .. "\n")
end

-- Get the plugin's root directory
local function get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
