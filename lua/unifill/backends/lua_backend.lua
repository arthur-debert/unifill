-- Lua backend implementation for unifill
-- This backend loads Unicode data from a Lua file
local log = require("unifill.log")
local constants = require("unifill.constants")
local Path = require("plenary.path")
local Job = require("plenary.job")
local vim = vim

local LuaBackend = {
    -- This is the only active backend
    active = true
}
LuaBackend.__index = LuaBackend

-- Create a new LuaBackend instance
-- @param config Table with configuration options
-- @return LuaBackend instance
function LuaBackend.new(config)
    local self = setmetatable({}, LuaBackend)
    self.config = config or {}
    
    -- Set default data path if not provided
    if not self.config.data_path then
        local plugin_root = self:get_plugin_root()
        -- Default to every-day dataset if not specified
        local dataset = self.config.dataset or constants.DEFAULT_DATASET
        self.config.data_path = plugin_root .. "/data/unicode." .. dataset .. ".lua"
    end

    return self
end

-- Get the plugin's root directory
-- @return String with the plugin root path
function LuaBackend:get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h:h:h:h")
end

-- Convert a code point to UTF-8
-- @param code_point String with the Unicode code point
-- @return String with the UTF-8 character
local function code_point_to_utf8(code_point)
    local n = tonumber(code_point, 16)
    if n <= 0x7F then
        return string.char(n)
    elseif n <= 0x7FF then
        local byte1 = bit.bor(0xC0, bit.rshift(n, 6))
        local byte2 = bit.bor(0x80, bit.band(n, 0x3F))
        return string.char(byte1, byte2)
    elseif n <= 0xFFFF then
        local byte1 = bit.bor(0xE0, bit.rshift(n, 12))
        local byte2 = bit.bor(0x80, bit.band(bit.rshift(n, 6), 0x3F))
        local byte3 = bit.bor(0x80, bit.band(n, 0x3F))
        return string.char(byte1, byte2, byte3)
    elseif n <= 0x10FFFF then
        local byte1 = bit.bor(0xF0, bit.rshift(n, 18))
        local byte2 = bit.bor(0x80, bit.band(bit.rshift(n, 12), 0x3F))
        local byte3 = bit.bor(0x80, bit.band(bit.rshift(n, 6), 0x3F))
        local byte4 = bit.bor(0x80, bit.band(n, 0x3F))
        return string.char(byte1, byte2, byte3, byte4)
    else
        log.error("Invalid code point: " .. code_point)
        return "�" -- Replacement character
    end
end

-- Load the Unicode data from the Lua module
-- @return Table with Unicode data entries
function LuaBackend:load_data()
    local start_time = vim.loop.hrtime()
    log.debug("Starting Lua unicode data load")
    local data_path = self.config.data_path
    log.debug("Data path:", data_path)

    -- Check if file exists
    local path = Path:new(data_path)
    local compressed_path = Path:new(data_path .. ".gz")
    
    -- Check for compressed file first
    if compressed_path:exists() then
        log.debug("Compressed Unicode data file found: " .. compressed_path.filename)
        -- Decompress the file
        local decompressed_path = data_path
        local success = self:decompress_file(compressed_path.filename, decompressed_path)
        if not success then
            local err_msg = "Failed to decompress Unicode data file: " .. compressed_path.filename
            log.error(err_msg)
            vim.notify(err_msg, vim.log.levels.ERROR)
            return {}
        end
        log.debug("Unicode data file decompressed successfully")
    elseif path:exists() then
        log.debug("Unicode data file found: " .. path.filename)
    else
        local err_msg = "Unicode data file not found at: " .. data_path .. " or " .. compressed_path.filename
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        -- CRITICAL: Never return an empty table when data loading fails
        -- This would allow tests to pass with no actual data, giving false positives
        error(err_msg)
    end

    -- Load the data
    local ok, data = pcall(dofile, data_path)
    if not ok then
        local err_msg = "Error loading unicode data: " .. tostring(data)
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        -- CRITICAL: Never return an empty table when data loading fails
        -- This would allow tests to pass with no actual data, giving false positives
        error(err_msg)
    end
    log.debug("Unicode data file loaded successfully")

    -- Validate data structure
    if type(data) ~= "table" or #data == 0 then
        local err_msg = "Invalid unicode data format"
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        -- CRITICAL: Never return an empty table when data loading fails
        -- This would allow tests to pass with no actual data, giving false positives
        error(err_msg)
    end
    log.debug("Unicode data validated, entries found:", #data)

    -- Convert characters to proper UTF-8
    local converted_count = 0
    for _, entry in ipairs(data) do
        if entry.character:match("\\u") then
            entry.character = code_point_to_utf8(entry.code_point)
            converted_count = converted_count + 1
        end
    end
    log.debug("UTF-8 conversion completed. Converted entries:", converted_count)

    local end_time = vim.loop.hrtime()
    local load_time_ms = (end_time - start_time) / 1000000
    log.info(string.format("Lua unicode data loaded successfully in %.2f ms, entries found: %d", load_time_ms, #data))

    return data
end

-- Get the entry structure for validation
-- @return Table with entry structure definition
function LuaBackend:get_entry_structure()
    return {
        name = "string", -- Unicode character name
        character = "string", -- The actual Unicode character
        code_point = "string", -- Unicode code point
        category = "string", -- Unicode category
        aliases = "table" -- Optional aliases (array of strings)
    }
end

-- Check if the backend is active
-- @return Boolean indicating if the backend is active
function LuaBackend:is_active()
    return self.active
end

-- Decompress a gzip compressed file
-- @param compressed_path String with the path to the compressed file
-- @param output_path String with the path to the output file
-- @return Boolean indicating if decompression was successful
function LuaBackend:decompress_file(compressed_path, output_path)
    log.debug("Decompressing file: " .. compressed_path .. " to " .. output_path)
    
    -- Check if gzip is available
    local gzip_check = Job:new({
        command = "which",
        args = { "gzip" },
    })
    
    gzip_check:sync()
    
    if gzip_check.code ~= 0 then
        log.error("gzip command not found. Please install gzip to decompress the dataset.")
        vim.notify("gzip command not found. Please install gzip to decompress the dataset.", vim.log.levels.ERROR)
        return false
    end
    
    -- Collect output from gzip command
    local output_data = {}
    
    -- Decompress the file using gzip
    local job = Job:new({
        command = "gzip",
        args = { "-d", "-c", compressed_path },
        on_stdout = function(_, data)
            table.insert(output_data, data)
        end,
    })
    
    job:sync()
    
    if job.code ~= 0 then
        log.error("Failed to decompress file: " .. compressed_path)
        return false
    end
    
    -- Write the decompressed data to the output file
    local file = io.open(output_path, "w")
    if not file then
        log.error("Failed to open output file for writing: " .. output_path)
        return false
    end
    
    for _, line in ipairs(output_data) do
        file:write(line .. "\n")
    end
    
    file:close()
    
    log.debug("File decompressed successfully")
    return true
end

return LuaBackend
