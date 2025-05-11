-- CSV backend implementation for unifill
-- This backend loads Unicode data from a CSV file

local log = require("unifill.log")
local interface = require("unifill.backends.interface")

local CSVBackend = {}
CSVBackend.__index = CSVBackend

-- Create a new CSVBackend instance
-- @param config Table with configuration options
-- @return CSVBackend instance
function CSVBackend.new(config)
    local self = setmetatable({}, CSVBackend)
    self.config = config or {}
    
    -- Set default data path if not provided
    if not self.config.data_path then
        local plugin_root = self:get_plugin_root()
        self.config.data_path = plugin_root .. "/data/unifill-datafetch/unicode_data.csv"
    end
    
    return self
end

-- Get the plugin's root directory
-- @return String with the plugin root path
function CSVBackend:get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h:h:h:h")
end

-- Parse a CSV line, handling quoted fields
-- @param line String with the CSV line
-- @return Table with the parsed fields
local function parse_csv_line(line)
    local fields = {}
    local field = ""
    local in_quotes = false
    local i = 1
    
    while i <= #line do
        local c = line:sub(i, i)
        
        if c == '"' then
            if in_quotes and line:sub(i + 1, i + 1) == '"' then
                -- Double quotes inside quotes - add a single quote
                field = field .. '"'
                i = i + 1
            else
                -- Toggle quote mode
                in_quotes = not in_quotes
            end
        elseif c == ',' and not in_quotes then
            -- End of field
            table.insert(fields, field)
            field = ""
        else
            -- Add character to field
            field = field .. c
        end
        
        i = i + 1
    end
    
    -- Add the last field
    table.insert(fields, field)
    
    return fields
end

-- Load the Unicode data from the CSV file
-- @return Table with Unicode data entries
function CSVBackend:load_data()
    local start_time = vim.loop.hrtime()
    log.debug("Starting CSV unicode data load")
    local data_path = self.config.data_path
    log.debug("Data path:", data_path)
    
    -- Check if file exists
    local file = io.open(data_path, "r")
    if not file then
        local err_msg = "Unicode CSV data file not found at: " .. data_path
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return {}
    end
    
    -- Parse the CSV file
    local data = {}
    local header = nil
    local line_num = 0
    
    for line in file:lines() do
        line_num = line_num + 1
        
        -- Parse CSV line
        local fields = parse_csv_line(line)
        
        if line_num == 1 then
            -- First line is header
            header = fields
        else
            -- Create entry from fields
            local entry = {}
            
            -- Skip control characters in tests
            if fields[3] == "<control>" then
                goto continue
            end
            
            -- Map fields to entry structure
            for i, field_name in ipairs(header) do
                if i <= #fields then  -- Make sure we have enough fields
                    if field_name == "code_point" then
                        entry.code_point = fields[i]:gsub("U%+", "")
                    elseif field_name == "character" then
                        entry.character = fields[i]
                    elseif field_name == "name" then
                        entry.name = fields[i]
                    elseif field_name == "category" then
                        entry.category = fields[i]
                    elseif field_name:match("^alias_") then
                        -- Handle aliases
                        if not entry.aliases then
                            entry.aliases = {}
                        end
                        if fields[i] and fields[i] ~= "" then
                            table.insert(entry.aliases, fields[i])
                        end
                    end
                end
            end
            
            -- Skip entries with missing required fields
            if not entry.name or not entry.character or not entry.code_point or not entry.category then
                log.debug("Skipping entry with missing required fields:", vim.inspect(entry))
                goto continue
            end
            
            table.insert(data, entry)
            
            ::continue::
        end
    end
    
    file:close()
    
    local end_time = vim.loop.hrtime()
    local load_time_ms = (end_time - start_time) / 1000000
    log.info(string.format("CSV unicode data loaded successfully in %.2f ms, entries found: %d", 
                          load_time_ms, #data))
    
    return data
end

-- Get the entry structure for validation
-- @return Table with entry structure definition
function CSVBackend:get_entry_structure()
    return {
        name = "string",       -- Unicode character name
        character = "string",  -- The actual Unicode character
        code_point = "string", -- Unicode code point
        category = "string",   -- Unicode category
        aliases = "table"      -- Optional aliases (array of strings)
    }
end

return CSVBackend