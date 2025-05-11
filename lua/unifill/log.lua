-- Logging functionality for unifill

-- Create a no-op logger for when plenary isn't available
local noop_logger = setmetatable({}, {
    __index = function(_, _)
        return function() end
    end
})

-- Try to set up plenary logging
local ok, plenary_log = pcall(require, 'plenary.log')
if not ok then
    return noop_logger
end

-- Set up logging with plenary
local cache_dir = vim.fn.stdpath('cache')
local log_path = cache_dir..'/unifill.log'
vim.fn.mkdir(cache_dir, 'p')

local log = plenary_log.new({
    plugin = 'unifill',
    level = vim.env.UNIFILL_LOG_LEVEL or "warn",
    filename = log_path,
    fmt_msg = function(_, level, msg)
        local info = debug.getinfo(4, "Sl")
        local fileinfo = info and string.format(" (%s:%s)", info.short_src, info.currentline) or ""
        return string.format('[%s]%s %s', level, fileinfo, msg)
    end,
})

if vim.env.PLENARY_TEST then
    pcall(function() log:set_level("error") end)
end

return log