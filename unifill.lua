-- unifill is a vim plugin to insert unicode characters.
-- it leverages telescope, that is it's written as telescope extension. 
-- we recommend the "<leader>+  iu" (insert unicode) :-), once that is pressed you get a telescope UI that can search unicode chars by the official name, any of it's common aliases and category, once selected the UI char will be inserted into your current buffer.

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- Get the plugin's root directory
local function get_plugin_root()
    -- Get the directory containing this file
    local source = debug.getinfo(1, "S").source
    local file = string.sub(source, 2) -- Remove the '@' prefix
    return vim.fn.fnamemodify(file, ":h")
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

-- Entry maker for telescope
local function entry_maker(entry)
    -- Create search text from name and aliases
    local search_text = entry.name
    if entry.aliases and #entry.aliases > 0 then
        search_text = search_text .. " " .. table.concat(entry.aliases, " ")
    end

    -- Create display text
    local display_text = string.format("%s - %s (%s) [%s]", 
        entry.character,
        entry.name,
        entry.code_point,
        entry.category
    )

    return {
        value = entry,
        display = display_text,
        ordinal = search_text
    }
end

-- Main picker function
local function unifill(opts)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = "Unicode Characters",
        finder = finders.new_table {
            results = load_unicode_data(),
            entry_maker = entry_maker
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                -- Insert the unicode character at cursor
                vim.api.nvim_put({ selection.value.character }, "", false, true)
            end)
            return true
        end,
    }):find()
end

-- Set up the key mapping
vim.keymap.set('n', '<leader>iu', unifill, { noremap = true, silent = true })

-- Return the module
return {
    unifill = unifill,
    _test = {
        load_unicode_data = load_unicode_data
    }
}
