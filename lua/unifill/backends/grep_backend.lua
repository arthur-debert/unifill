-- Grep backend implementation for unifill
-- This backend uses ripgrep (or another grep tool) to search through a text file
local log = require("unifill.log")
local constants = require("unifill.constants")

-- Only require telescope modules when not in test environment
local has_telescope, finders = pcall(require, "telescope.finders")

local GrepBackend = {
    -- This backend is inactive
    active = false
}
GrepBackend.__index = GrepBackend

-- Create a new GrepBackend instance
-- @param config Table with configuration options
-- @return GrepBackend instance
function GrepBackend.new(config)
    local self = setmetatable({}, GrepBackend)
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
function GrepBackend:get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h:h:h:h")
end

-- Parse a line from the grep output
-- @param line String with the grep output line
-- @return Table with the parsed entry
function GrepBackend.parse_grep_line(line)
    local parts = vim.split(line, "|", {
        plain = true
    })
    if #parts < 4 then
        log.debug("Invalid grep line format:", line)
        return nil
    end

    local entry = {
        character = parts[1],
        name = parts[2],
        code_point = parts[3],
        category = parts[4],
        aliases = {}
    }

    -- Add aliases if they exist
    for i = 5, #parts do
        if parts[i] and parts[i] ~= "" then
            table.insert(entry.aliases, parts[i])
        end
    end

    return entry
end

-- Create a command generator function for telescope
-- @param prompt String with the search prompt
-- @return Table with command configuration
function GrepBackend:create_command_generator(prompt)
    if prompt == "" then
        return nil
    end

    -- For multi-word searches, we need to search for each word separately
    local words = {}
    for word in prompt:gmatch("%S+") do
        table.insert(words, word)
    end

    -- Escape special characters in the prompt
    local escaped_prompt = prompt:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "\\%1")

    -- For benchmark, use a simpler command that works with the file path
    if #words > 1 then
        return {
            command = self.config.grep_command,
            args = {"--no-heading", "--line-number", "-i", -- Case insensitive
            "-e", escaped_prompt, self.config.data_path}
        }
    else
        return {
            command = self.config.grep_command,
            args = {"--no-heading", "--line-number", "-i", -- Case insensitive
            escaped_prompt, self.config.data_path}
        }
    end
end

-- Load the Unicode data using grep
-- @return Table with finder configuration or empty table
function GrepBackend:load_data()
    local start_time = vim.loop.hrtime()
    log.debug("Starting grep unicode data load")

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
    log.info(string.format("Grep backend initialized in %.2f ms", load_time_ms))

    -- In test environment, return an empty table
    if not has_telescope then
        log.debug("Telescope not available, returning empty table")
        return {}
    end

    -- Return a function that will be used by the finder
    return function(prompt)
        return finders.new_oneshot_job({self.config.grep_command, "--no-heading", "--line-number", prompt,
                                        self.config.data_path}, {
            entry_maker = function(line)
                return GrepBackend.parse_grep_line(line)
            end
        })
    end
end

-- Get the entry structure for validation
-- @return Table with entry structure definition
function GrepBackend:get_entry_structure()
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
function GrepBackend:is_active()
    return self.active
end

return GrepBackend
