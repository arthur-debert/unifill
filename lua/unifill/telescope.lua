-- Telescope integration for unifill

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local format = require("unifill.format")
local search = require("unifill.search")
local log = require("unifill.log")

-- Custom sorter for telescope
local function custom_sorter(opts)
    log.debug("Creating custom sorter with opts:", vim.inspect(opts))
    return require("telescope.sorters").Sorter:new {
        scoring_function = function(_, prompt, line)
            if prompt == "" then
                log.debug("Empty prompt, returning default score")
                return 1
            end

            -- For telescope, convert our score to its convention (lower is better)
            local terms = vim.split(prompt, "%s+")
            log.debug("Scoring entry for terms:", vim.inspect(terms))
            log.debug("Entry being scored:", line.value.name)
            
            local test_score = search.score_match(line.value, terms)
            
            -- Convert score: 0 becomes -1 (filtered), higher becomes lower (better match)
            if test_score == 0 then
                log.debug("Entry filtered out:", line.value.name)
                return -1
            end
            local final_score = 1 / test_score
            log.debug(string.format("Final telescope score for '%s': %s (original: %s)",
                line.value.name, final_score, test_score))
            return final_score
        end,

        highlighter = opts.highlighter or function(_, prompt, display)
            -- Highlight matching terms
            local highlights = {}
            local terms = vim.split(prompt:lower(), "%s+")
            local display_lower = display:lower()
            
            for _, term in ipairs(terms) do
                local pattern = "%f[%w_]" .. vim.pesc(term) .. "%f[^%w_]"
                local start = display_lower:find(pattern)
                if start then
                    table.insert(highlights, {
                        start = start,
                        finish = start + #term - 1
                    })
                end
            end
            
            return highlights
        end
    }
end

-- Entry maker for telescope
local function entry_maker(entry)
    -- Skip control characters
    if entry.category == "Cc" or entry.category == "Cn" then
        log.debug("Skipping control character:", entry.name)
        return nil
    end

    -- Format the name and category
    local name = format.to_title_case(entry.name)
    local aliases = format.format_aliases(entry.aliases)
    local category = format.friendly_category(entry.category)

    -- Create display text with more spacing for readability
    local display_text = string.format("%s     %s%s (%s)",
        entry.character,
        name,
        aliases,
        category
    )

    log.debug(string.format("Created telescope entry for '%s': %s",
        entry.name, display_text))

    return {
        value = entry,
        display = display_text,
        ordinal = entry.name
    }
end

return {
    custom_sorter = custom_sorter,
    entry_maker = entry_maker
}