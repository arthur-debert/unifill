-- Data loading functionality for unifill

-- Import the logger directly
local log = require("unifill.log")

-- Get the plugin's root directory
local function get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h:h:h")
end

-- Load the unicode data from the Lua module
local function load_unicode_data()
    log.debug("Starting unicode data load")
    local plugin_root = get_plugin_root()
    local data_path = plugin_root .. "/data/unifill-datafetch/unicode_data.lua"
    log.debug("Data path:", data_path)
    
    -- Check if file exists
    local file = io.open(data_path, "r")
    if not file then
        local err_msg = "Unicode data file not found at: " .. data_path
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return {}
    end
    file:close()
    log.debug("Unicode data file found")
    
    -- Load the data
    local ok, data = pcall(dofile, data_path)
    if not ok then
        local err_msg = "Error loading unicode data: " .. tostring(data)
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return {}
    end
    log.debug("Unicode data file loaded successfully")
    
    -- Validate data structure
    if type(data) ~= "table" or #data == 0 then
        local err_msg = "Invalid unicode data format"
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return {}
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
    
    log.debug("Unicode data loading completed successfully")
    return data
end

return {
    get_plugin_root = get_plugin_root,
    load_unicode_data = load_unicode_data
}