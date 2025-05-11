-- Data management functionality for unifill
-- This module manages the data backends and provides a unified interface

local log = require("unifill.log")

-- Data Manager
local DataManager = {}

-- Default configuration
local default_config = {
    backend = "lua",
    backends = {
        lua = {
            -- Will be set based on plugin root
            data_path = nil
        }
    }
}

-- Current configuration
local config = vim.deepcopy(default_config)

-- Get the plugin's root directory
local function get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h:h:h")
end

-- Setup the data manager with configuration
-- @param user_config Table with user configuration
-- @return DataManager for chaining
function DataManager.setup(user_config)
    -- Merge user config with defaults
    config = vim.tbl_deep_extend("force", default_config, user_config or {})
    
    -- Set default paths based on plugin root if not provided
    local plugin_root = get_plugin_root()
    if not config.backends.lua.data_path then
        config.backends.lua.data_path = plugin_root .. "/data/unifill-datafetch/unicode_data.lua"
    end
    
    log.debug("DataManager setup complete with backend: " .. config.backend)
    return DataManager
end

-- Validate data entries against expected structure
-- @param data Table with data entries
-- @param structure Table with expected structure
-- @return Boolean indicating if data is valid
local function validate_data(data, structure)
    if type(data) ~= "table" or #data == 0 then
        log.error("Invalid data format: not a table or empty")
        return false
    end
    
    -- Check first entry structure
    local entry = data[1]
    for field, expected_type in pairs(structure) do
        if type(entry[field]) ~= expected_type and
           not (expected_type == "table" and entry[field] == nil) then
            log.error("Invalid entry structure: field '" .. field ..
                      "' should be " .. expected_type ..
                      " but is " .. type(entry[field]))
            return false
        end
    end
    
    return true
end

-- Load the Unicode data using the configured backend
-- @return Table with Unicode data entries
function DataManager.load_unicode_data()
    log.debug("Loading unicode data with backend: " .. config.backend)
    
    -- Get backend configuration
    local backend_name = config.backend
    local backend_config = config.backends[backend_name]
    
    if backend_name == "lua" then
        -- Load Lua backend
        local LuaBackend = require("unifill.backends.lua_backend")
        local backend = LuaBackend.new(backend_config)
        
        -- Load data
        local data = backend:load_data()
        
        -- Validate data structure
        if not validate_data(data, backend:get_entry_structure()) then
            log.error("Data validation failed")
            return {}
        end
        
        return data
    else
        -- Unknown backend
        local err_msg = "Unknown backend: " .. backend_name
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return {}
    end
end

-- Initialize with default configuration
DataManager.setup()

return {
    setup = DataManager.setup,
    get_plugin_root = get_plugin_root,
    load_unicode_data = DataManager.load_unicode_data
}