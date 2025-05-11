-- Logging functionality for unifill

-- Set up direct file logging
local log_dir = vim.fn.expand('%:p:h:h:h') .. '/tmp/logs'
local log_path = log_dir..'/unifill.log'
vim.fn.mkdir(log_dir, 'p')

-- Clear previous log file
local f = io.open(log_path, "w")
if f then
    f:write("Unifill log started at " .. os.date() .. "\n")
    f:close()
end

-- Print log location for easy reference
vim.api.nvim_echo({{"Unifill logs at: " .. log_path, "Normal"}}, true, {})

-- Simple logger implementation
local log = {}

local function write_log(level, ...)
    local args = {...}
    local msg = ""
    
    for i, v in ipairs(args) do
        if type(v) == "table" then
            msg = msg .. vim.inspect(v)
        else
            msg = msg .. tostring(v)
        end
        
        if i < #args then
            msg = msg .. " "
        end
    end
    
    local info = debug.getinfo(3, "Sl")
    local fileinfo = info and string.format(" (%s:%s)", info.short_src, info.currentline) or ""
    local log_msg = string.format('[%s]%s %s\n', level, fileinfo, msg)
    
    local f = io.open(log_path, "a")
    if f then
        f:write(log_msg)
        f:close()
    end
end

function log.debug(...)
    write_log("DEBUG", ...)
end

function log.info(...)
    write_log("INFO", ...)
end

function log.warn(...)
    write_log("WARN", ...)
end

function log.error(...)
    write_log("ERROR", ...)
end

return log