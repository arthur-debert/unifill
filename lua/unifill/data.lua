-- Data loading functionality for unifill

-- Get the plugin's root directory
local function get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h:h:h")
end

-- Load the unicode data from the Lua module
local function load_unicode_data()
    local plugin_root = get_plugin_root()
    local data_path = plugin_root .. "/data/unifill-datafetch/unicode_data.lua"
    
    -- Check if file exists
    local file = io.open(data_path, "r")
    if not file then
        vim.notify("Unicode data file not found at: " .. data_path, vim.log.levels.ERROR)
        return {}
    end
    file:close()
    
    -- Load the data
    local ok, data = pcall(dofile, data_path)
    if not ok then
        vim.notify("Error loading unicode data: " .. tostring(data), vim.log.levels.ERROR)
        return {}
    end
    
    -- Validate data structure
    if type(data) ~= "table" or #data == 0 then
        vim.notify("Invalid unicode data format", vim.log.levels.ERROR)
        return {}
    end
    
    -- Convert characters to proper UTF-8
    for _, entry in ipairs(data) do
        if entry.character:match("\\u") then
            entry.character = code_point_to_utf8(entry.code_point)
        end
    end
    return data
end

return {
    get_plugin_root = get_plugin_root,
    load_unicode_data = load_unicode_data
}