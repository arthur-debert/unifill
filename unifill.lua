-- unifill is a vim plugin to insert unicode characters.
--- it leverages telescope, that is it's written as telescope extension. 
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

-- Helper function to convert to title case
local function to_title_case(str)
    -- Split on spaces and hyphens
    local words = vim.split(str:lower(), "[-_ ]")
    for i, word in ipairs(words) do
        words[i] = word:sub(1,1):upper() .. word:sub(2)
    end
    return table.concat(words, " ")
end

-- Helper function to format aliases
local function format_aliases(aliases)
    if not aliases or #aliases == 0 then
        return ""
    end
    return string.format(" (aka %s)", table.concat(
        vim.tbl_map(function(a) return to_title_case(a) end, aliases),
        ", "
    ))
end

-- Helper function to get friendly category name
local function friendly_category(cat)
    local categories = {
        Lu = "Uppercase Letter",
        Ll = "Lowercase Letter",
        Lt = "Titlecase Letter",
        Lm = "Modifier Letter",
        Lo = "Other Letter",
        Mn = "Non-spacing Mark",
        Mc = "Spacing Mark",
        Me = "Enclosing Mark",
        Nd = "Decimal Number",
        Nl = "Letter Number",
        No = "Other Number",
        Pc = "Connector Punctuation",
        Pd = "Dash Punctuation",
        Ps = "Open Punctuation",
        Pe = "Close Punctuation",
        Pi = "Initial Punctuation",
        Pf = "Final Punctuation",
        Po = "Other Punctuation",
        Sm = "Math Symbol",
        Sc = "Currency Symbol",
        Sk = "Modifier Symbol",
        So = "Other Symbol",
        Zs = "Space Separator",
        Zl = "Line Separator",
        Zp = "Paragraph Separator",
    }
    return categories[cat] or cat
end

-- Entry maker for telescope
-- Helper function to check word matches
local function check_word_match(text, term)
    text = text:lower()
    term = term:lower()
    
    -- Split text into words
    local words = {}
    for word in text:gmatch("[%w_]+") do
        -- Check for exact word match (highest priority)
        if word == term then
            return 2  -- Exact word match
        end
        -- Check for word-part match (lower priority)
        if word:find("^" .. vim.pesc(term)) then
            return 1  -- Word-part match
        end
    end
    
    return 0  -- No match
end

-- Score a match based on where terms are found
local function score_match(entry, terms)
    if not entry or not entry.name or not entry.category then
        return 0
    end

    local matched_terms = {}
    local total_score = 0

    -- Check each term
    for _, term in ipairs(terms) do
        local found = false
        local best_match = 0
        local location = 0  -- 0=none, 1=category, 2=alias, 3=name
        
        -- Check name (highest priority)
        local name_match = check_word_match(entry.name, term)
        if name_match > 0 then
            -- Any match in name scores higher than any match in alias
            total_score = total_score + 1000000000000  -- Base score for name location
            found = true
        end
        
        -- Check aliases (medium priority)
        if not found and entry.aliases then
            for _, alias in ipairs(entry.aliases) do
                local alias_match = check_word_match(alias, term)
                if alias_match > 0 then
                    -- Only count exact word matches in aliases
                    if alias_match == 2 then
                        total_score = total_score + 1  -- Much lower score for alias matches
                        found = true
                        break
                    end
                end
            end
        end
        
        -- Check category (lowest priority)
        if not found then
            local category_match = check_word_match(friendly_category(entry.category), term)
            if category_match == 2 then  -- Only count exact word matches in category
                total_score = total_score + 0.0001  -- Lowest score for category matches
                found = true
            end
        end

        if found then
            matched_terms[term] = true
        end
    end

    -- Return 0 if not all terms matched
    if vim.tbl_count(matched_terms) < #terms then
        return 0
    end

    -- Return total score multiplied by number of matched terms
    return total_score * vim.tbl_count(matched_terms)
end

-- Custom sorter for telescope
local function custom_sorter(opts)
    return require("telescope.sorters").Sorter:new {
        scoring_function = function(_, prompt, line)
            if prompt == "" then
                return 1
            end

            -- For telescope, convert our score to its convention (lower is better)
            local terms = vim.split(prompt, "%s+")
            local test_score = score_match(line.value, terms)
            
            -- Convert score: 0 becomes -1 (filtered), higher becomes lower (better match)
            if test_score == 0 then
                return -1
            end
            return 1 / test_score
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
        return nil
    end

    -- Format the name and category
    local name = to_title_case(entry.name)
    local aliases = format_aliases(entry.aliases)
    local category = friendly_category(entry.category)

    -- Create display text with more spacing for readability
    local display_text = string.format("%s     %s%s (%s)",
        entry.character,
        name,
        aliases,
        category
    )

    return {
        value = entry,
        display = display_text,
        ordinal = entry.name
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
        sorter = custom_sorter(opts),
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
        load_unicode_data = load_unicode_data,
        entry_maker = entry_maker,
        to_title_case = to_title_case,
        format_aliases = format_aliases,
        friendly_category = friendly_category,
        score_match = score_match
    }
}
