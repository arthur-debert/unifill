-- Data management functionality for unifill
-- This module manages the data backends and provides a unified interface
local log = require("unifill.log")
local constants = require("unifill.constants")
local Job = require("plenary.job")
local Path = require("plenary.path")

-- Data Manager
local DataManager = {}

-- Default configuration
local default_config = {
    backend = "lua",
    dataset = constants.DEFAULT_DATASET, -- Default dataset to use (every-day or complete)
    results_limit = constants.DEFAULT_RESULTS_LIMIT, -- Default number of results to display
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

-- @return Boolean indicating if decompression was successful
local function decompress_file(compressed_path, output_path, format)
    log.debug("Decompressing file: " .. compressed_path .. " to " .. output_path)
    
    local command, args
    if format == "gzip" then
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
        
        command = "gzip"
        args = { "-d", "-c", compressed_path }
    elseif format == "zstd" then
        -- Check if zstd is available
        local zstd_check = Job:new({
            command = "which",
            args = { "zstd" },
        })
        
        zstd_check:sync()
        
        if zstd_check.code ~= 0 then
            log.error("zstd command not found. Please install zstd to decompress the dataset.")
            vim.notify("zstd command not found. Please install zstd to decompress the dataset.", vim.log.levels.ERROR)
            return false
        end
        
        command = "zstd"
        args = { "-d", compressed_path, "-f", "-o", output_path }
        
        -- Run the decompression command
        local job = Job:new({
            command = command,
            args = args,
        })
        
        job:sync()
        
        if job.code ~= 0 then
            log.error("Failed to decompress file: " .. compressed_path)
            return false
        end
        
        return true
    else
        log.error("Unknown compression format: " .. format)
        return false
    end
    
    -- For gzip, we need to write the output to a file
    if format == "gzip" then
        -- Use io.popen to capture the output of the command
        local cmd = command .. " " .. table.concat(args, " ")
        local handle = io.popen(cmd, "r")
        if not handle then
            log.error("Failed to execute command: " .. cmd)
            return false
        end
        
        -- Read the output
        local output = handle:read("*a")
        handle:close()
        
        -- Write the output to the file
        local file = io.open(output_path, "w")
        if not file then
            log.error("Failed to open output file for writing: " .. output_path)
            return false
        end
        
        file:write(output)
        file:close()
    end
    
    log.debug("File decompressed successfully")
    return true
end

-- Check if a file exists or if a compressed version exists, and decompress if needed
-- @param base_path String with the base path of the file (without extension)
-- @param extension String with the file extension (e.g., ".lua")
-- @return String with the path to the uncompressed file, or nil if not found
local function ensure_uncompressed_file(base_path, extension)
    local file_path = base_path .. extension
    local path = Path:new(file_path)
    
    -- Check if uncompressed file exists
    if path:exists() then
        log.debug("Found uncompressed file: " .. file_path)
        return file_path
    end
    
    -- Check for compressed versions
    local gz_path = Path:new(file_path .. ".gz")
    local zst_path = Path:new(file_path .. ".zst")  -- For backward compatibility
    
    if gz_path:exists() then
        log.debug("Found gzip compressed file: " .. gz_path.filename)
        -- Decompress the file
        local success = decompress_file(gz_path.filename, file_path, "gzip")
        if success then
            log.debug("Successfully decompressed file: " .. gz_path.filename)
            return file_path
        else
            log.error("Failed to decompress file: " .. gz_path.filename)
            return nil
        end
    elseif zst_path:exists() then
        log.debug("Found zstd compressed file: " .. zst_path.filename)
        -- Decompress the file
        local success = decompress_file(zst_path.filename, file_path, "zstd")
        if success then
            log.debug("Successfully decompressed file: " .. zst_path.filename)
            return file_path
        else
            log.error("Failed to decompress file: " .. zst_path.filename)
            return nil
        end
    end
    
    -- No file found
    log.debug("No file found at: " .. file_path .. " or compressed versions")
    return nil
end

-- Decompress a file
-- @param compressed_path String with the path to the compressed file
-- @param output_path String with the path to the output file
-- @param format String with the compression format ("gzip" or "zstd")

-- Setup the data manager with configuration
-- @param user_config Table with user configuration
-- @return DataManager for chaining
function DataManager.setup(user_config)
    -- Merge user config with defaults
    config = vim.tbl_deep_extend("force", default_config, user_config or {})
    
    -- Ensure results limit doesn't exceed maximum
    if config.results_limit > constants.MAX_RESULTS_LIMIT then
        log.warn(string.format("Config results limit %d exceeds maximum of %d, capping at maximum",
            config.results_limit, constants.MAX_RESULTS_LIMIT))
        config.results_limit = constants.MAX_RESULTS_LIMIT
    end

    -- Set default paths based on XDG directories if available, otherwise use plugin root
    local plugin_root = get_plugin_root()
    local xdg_data_dir = get_xdg_data_home() .. "/unifill"
    local dataset = config.dataset
    
    -- Base paths for dataset files
    local xdg_base_path = xdg_data_dir .. "/unicode." .. dataset
    local plugin_base_path = plugin_root .. "/data/unicode." .. dataset
    
    -- Set paths based on availability, checking for compressed versions if needed
    if not config.backends.lua.data_path then
        -- Try XDG path first
        local xdg_lua_path = ensure_uncompressed_file(xdg_base_path, ".lua")
        if xdg_lua_path then
            config.backends.lua.data_path = xdg_lua_path
        else
            -- Try plugin path
            local plugin_lua_path = ensure_uncompressed_file(plugin_base_path, ".lua")
            if plugin_lua_path then
                config.backends.lua.data_path = plugin_lua_path
            else
                -- Fall back to default path (may not exist)
                config.backends.lua.data_path = plugin_base_path .. ".lua"
            end
        end
    end
    
    if not config.backends.csv.data_path then
        -- Try XDG path first
        local xdg_csv_path = ensure_uncompressed_file(xdg_base_path, ".csv")
        if xdg_csv_path then
            config.backends.csv.data_path = xdg_csv_path
        else
            -- Try plugin path
            local plugin_csv_path = ensure_uncompressed_file(plugin_base_path, ".csv")
            if plugin_csv_path then
                config.backends.csv.data_path = plugin_csv_path
            else
                -- Fall back to default path (may not exist)
                config.backends.csv.data_path = plugin_base_path .. ".csv"
            end
        end
    end
    
    if not config.backends.grep.data_path then
        -- Try XDG path first
        local xdg_txt_path = ensure_uncompressed_file(xdg_base_path, ".txt")
        if xdg_txt_path then
            config.backends.grep.data_path = xdg_txt_path
        else
            -- Try plugin path
            local plugin_txt_path = ensure_uncompressed_file(plugin_base_path, ".txt")
            if plugin_txt_path then
                config.backends.grep.data_path = plugin_txt_path
            else
                -- Fall back to default path (may not exist)
                config.backends.grep.data_path = plugin_base_path .. ".txt"
            end
        end
    end
    
    if not config.backends.fast_grep.data_path then
        -- Use the same path as grep backend
        config.backends.fast_grep.data_path = config.backends.grep.data_path
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
    log.debug("Loading unicode data with backend: " .. config.backend .. " and dataset: " .. config.dataset)

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

    -- Check if backend is active
    if not backend:is_active() then
        local err_msg = "Backend '" .. backend_name .. "' is not active. Please use an active backend."
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

-- Get the current dataset name
-- @return String with the current dataset name
function DataManager.get_dataset()
    return config.dataset
end

return {
    setup = DataManager.setup,
    get_plugin_root = get_plugin_root,
    load_unicode_data = DataManager.load_unicode_data,
    get_backend_name = DataManager.get_backend_name,
    get_config = DataManager.get_config,
    get_dataset = DataManager.get_dataset,
    -- Export for testing
    _ensure_uncompressed_file = ensure_uncompressed_file,
    _decompress_file = decompress_file
}
