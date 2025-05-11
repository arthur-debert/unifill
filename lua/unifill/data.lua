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
        },
        csv = {
            -- Will be set based on plugin root
            data_path = nil
        },
        grep = {
            -- Will be set based on plugin root
            data_path = nil,
            -- Default grep command
            grep_command = "rg"
        },
        fast_grep = {
            -- Will be set based on plugin root
            data_path = nil,
            -- Default grep command
            grep_command = "rg"
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

-- Get XDG data directory
local function get_xdg_data_home()
    local xdg_data = os.getenv("XDG_DATA_HOME")
    if xdg_data then
        return xdg_data
    else
        return vim.fn.expand("~/.local/share")
    end
end

-- Get XDG cache directory
local function get_xdg_cache_home()
    local xdg_cache = os.getenv("XDG_CACHE_HOME")
    if xdg_cache then
        return xdg_cache
    else
        return vim.fn.expand("~/.cache")
    end
end

-- Setup the data manager with configuration
-- @param user_config Table with user configuration
-- @return DataManager for chaining
function DataManager.setup(user_config)
    -- Merge user config with defaults
    config = vim.tbl_deep_extend("force", default_config, user_config or {})

    -- Set default paths based on XDG directories if available, otherwise use plugin root
    local plugin_root = get_plugin_root()
    local xdg_data_dir = get_xdg_data_home() .. "/unifill"
    
    -- Check if data files exist in XDG data directory
    local Path = require("plenary.path")
    local xdg_lua_path = Path:new(xdg_data_dir, "unicode_data.lua")
    local xdg_csv_path = Path:new(xdg_data_dir, "unicode_data.csv")
    local xdg_txt_path = Path:new(xdg_data_dir, "unicode_data.txt")
    
    -- Set paths based on availability
    if not config.backends.lua.data_path then
        if xdg_lua_path:exists() then
            config.backends.lua.data_path = xdg_lua_path.filename
        else
            config.backends.lua.data_path = plugin_root .. "/data/unicode_data.lua"
        end
    end
    
    if not config.backends.csv.data_path then
        if xdg_csv_path:exists() then
            config.backends.csv.data_path = xdg_csv_path.filename
        else
            config.backends.csv.data_path = plugin_root .. "/data/unicode_data.csv"
        end
    end
    
    if not config.backends.grep.data_path then
        if xdg_txt_path:exists() then
            config.backends.grep.data_path = xdg_txt_path.filename
        else
            config.backends.grep.data_path = plugin_root .. "/data/unicode_data.txt"
        end
    end
    
    if not config.backends.fast_grep.data_path then
        if xdg_txt_path:exists() then
            config.backends.fast_grep.data_path = xdg_txt_path.filename
        else
            config.backends.fast_grep.data_path = plugin_root .. "/data/unicode_data.txt"
        end
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
        if type(entry[field]) ~= expected_type and not (expected_type == "table" and entry[field] == nil) then
            log.error("Invalid entry structure: field '" .. field .. "' should be " .. expected_type .. " but is " ..
                          type(entry[field]))
            return false
        end
    end

    return true
end

-- Load the Unicode data using the configured backend
-- @return Table with Unicode data entries
function DataManager.load_unicode_data()
    local start_time = vim.loop.hrtime()
    log.debug("Loading unicode data with backend: " .. config.backend)

    -- Get backend configuration
    local backend_name = config.backend
    local backend_config = config.backends[backend_name]

    -- Load the appropriate backend
    local backend = nil

    if backend_name == "lua" then
        local LuaBackend = require("unifill.backends.lua_backend")
        backend = LuaBackend.new(backend_config)
    elseif backend_name == "csv" then
        local CSVBackend = require("unifill.backends.csv_backend")
        backend = CSVBackend.new(backend_config)
    elseif backend_name == "grep" then
        local GrepBackend = require("unifill.backends.grep_backend")
        backend = GrepBackend.new(backend_config)
    elseif backend_name == "fast_grep" then
        local FastGrepBackend = require("unifill.backends.fast_grep_backend")
        backend = FastGrepBackend.new(backend_config)
    else
        -- Unknown backend
        local err_msg = "Unknown backend: " .. backend_name
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return {}
    end

    -- Load data
    local data = backend:load_data()

    -- Validate data structure
    if not validate_data(data, backend:get_entry_structure()) then
        log.error("Data validation failed")
        return {}
    end

    local end_time = vim.loop.hrtime()
    local load_time_ms = (end_time - start_time) / 1000000
    log.info(string.format("Backend '%s' loaded %d entries in %.2f ms", backend_name, #data, load_time_ms))

    return data
end

-- Initialize with default configuration
DataManager.setup()

-- Get the current backend name
-- @return String with the current backend name
function DataManager.get_backend_name()
    return config.backend
end

-- Get the current configuration
-- @return Table with the current configuration
function DataManager.get_config()
    return config
end

return {
    setup = DataManager.setup,
    get_plugin_root = get_plugin_root,
    load_unicode_data = DataManager.load_unicode_data,
    get_backend_name = DataManager.get_backend_name,
    get_config = DataManager.get_config
}
