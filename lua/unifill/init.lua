-- unifill is a vim plugin to insert unicode characters.
-- it leverages telescope, that is it's written as telescope extension. 
-- we recommend the "<leader>+  iu" (insert unicode) :-), once that is pressed you get a telescope UI that can search unicode chars by the official name, any of it's common aliases and category, once selected the UI char will be inserted into your current buffer.

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local data = require("unifill.data")
local format = require("unifill.format")
local telescope_utils = require("unifill.telescope")

-- Main picker function
local function unifill(opts)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = "Unicode Characters",
        finder = finders.new_table {
            results = data.load_unicode_data(),
            entry_maker = telescope_utils.entry_maker
        },
        sorter = telescope_utils.custom_sorter(opts),
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
vim.keymap.set('n', '<leader>fu', unifill, { noremap = true, silent = true })

-- Return the module
return {
    unifill = unifill,
    _test = {
        load_unicode_data = data.load_unicode_data,
        entry_maker = telescope_utils.entry_maker,
        to_title_case = format.to_title_case,
        format_aliases = format.format_aliases,
        friendly_category = format.friendly_category,
        score_match = require("unifill.search").score_match
    }
}