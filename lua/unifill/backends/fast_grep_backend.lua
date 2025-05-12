-- Fast Grep backend implementation for unifill
-- This backend uses ripgrep with minimal Lua processing, leveraging Telescope's native capabilities
local log = require("unifill.log")
local interface = require("unifill.backends.interface")
local constants = require("unifill.constants")

-- Only require telescope modules when not in test environment
local has_telescope, finders = pcall(require, "telescope.finders")
local _, sorters = pcall(require, "telescope.sorters")
local _, previewers = pcall(require, "telescope.previewers")
local _, actions = pcall(require, "telescope.actions")
local _, action_state = pcall(require, "telescope.actions.state")
local _, entry_display = pcall(require, "telescope.pickers.entry_display")

local FastGrepBackend = {
    -- This backend is inactive
    active = false
}
FastGrepBackend.__index = FastGrepBackend

-- Create a new FastGrepBackend instance
-- @param config Table with configuration options
-- @return FastGrepBackend instance
function FastGrepBackend.new(config)
    local self = setmetatable({}, FastGrepBackend)
    self.config = config or {}

    -- Set default data path if not provided
    if not self.config.data_path then
        local plugin_root = self:get_plugin_root()
        -- Default to every-day dataset if not specified
        local dataset = self.config.dataset or constants.DEFAULT_DATASET
        self.config.data_path = plugin_root .. "/data/unicode." .. dataset .. ".txt"
    end

    -- Set default grep command if not provided
    self.config.grep_command = self.config.grep_command or "rg"

    return self
end

-- Get the plugin's root directory
-- @return String with the plugin root path
function FastGrepBackend:get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h:h:h:h")
end

-- Create a command generator function for telescope
-- @param prompt String with the search prompt
-- @return Table with command configuration
function FastGrepBackend:create_command_generator(prompt)
    if prompt == "" then
        return nil
    end

    -- Escape special characters in the prompt
    local escaped_prompt = prompt:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "\\%1")

    -- Create a simple command that leverages ripgrep's speed
    return {
        command = self.config.grep_command,
        args = {"--no-heading", "--line-number", "-i", -- Case insensitive
        escaped_prompt, self.config.data_path}
    }
end

-- Create a minimal entry maker that does very little processing
-- @param line String with the grep output line
-- @return Table with the entry for telescope
function FastGrepBackend.make_entry(line)
    -- Split the line by pipe character
    local parts = vim.split(line, "|", {
        plain = true
    })
    if #parts < 4 then
        return nil
    end

    -- Extract only the essential fields with minimal processing
    local character = parts[1]
    local name = parts[2]
    local code_point = parts[3]
    local category = parts[4]

    -- Create a simple display string
    local display_str = character .. " " .. name .. " (" .. code_point .. ")"

    -- Return a minimal entry structure
    return {
        value = character,
        ordinal = name .. " " .. table.concat(parts, " ", 5), -- Include aliases in search
        display = display_str,
        character = character,
        name = name,
        code_point = code_point,
        category = category
    }
end

-- Load the Unicode data using grep
-- @return Table with finder configuration or empty table
function FastGrepBackend:load_data()
    local start_time = vim.loop.hrtime()
    log.debug("Starting fast grep unicode data load")

    -- Check if file exists
    local file = io.open(self.config.data_path, "r")
    if not file then
        local err_msg = "Unicode data file not found at: " .. self.config.data_path
        log.error(err_msg)
        vim.notify(err_msg, vim.log.levels.ERROR)
        return {}
    end
    file:close()

    local end_time = vim.loop.hrtime()
    local load_time_ms = (end_time - start_time) / 1000000
    log.info(string.format("Fast grep backend initialized in %.2f ms", load_time_ms))

    -- In test environment, return an empty table
    if not has_telescope then
        log.debug("Telescope not available, returning empty table")
        return {}
    end

    -- Return a function that creates a finder with minimal processing
    return function(prompt)
        if prompt == "" then
            -- For empty prompt, return a dummy finder to avoid searching everything
            return finders.new_table({
                results = {},
                entry_maker = function()
                    return {}
                end
            })
        end

        -- Create a job finder that uses ripgrep directly
        return finders.new_oneshot_job(
            {self.config.grep_command, "--no-heading", "--line-number", "-i", -- Case insensitive
            prompt, self.config.data_path}, {
                entry_maker = FastGrepBackend.make_entry
            })
    end
end

-- Get the entry structure for validation
-- @return Table with entry structure definition
function FastGrepBackend:get_entry_structure()
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
function FastGrepBackend:is_active()
    return self.active
end

return FastGrepBackend
