-- Search functionality for unifill

local format = require("unifill.format")

-- Helper function to check word matches in text
-- Returns:
-- 2: Exact word match (e.g., "right" matches "RIGHT" or "ARROW POINTING RIGHT")
-- 1: Word start match (e.g., "right" matches "RIGHTWARDS")
-- 0: No match
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
--
-- Scores matches based on two factors:
-- 1. Location priority: name > alias > category
-- 2. Match quality: exact word > word start
--
-- For each search term, finds the best match across all locations.
-- A term must match somewhere for the entry to be considered.
--
-- Scoring:
-- - Name matches: 1000000000000 points (any match quality)
-- - Alias matches: 1 point (exact word matches only)
-- - Category matches: 0.0001 points (exact word matches only)
--
-- Example:
-- Entry: { name = "RIGHTWARDS ARROW", aliases = {"FORWARD"} }
-- Terms: {"right"}
-- Result: 1000000000000 (word start match in name)
--
-- @param entry Table with name, category, and optional aliases
-- @param terms Array of search terms
-- @return Score, or 0 if any term doesn't match
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
            local category_match = check_word_match(format.friendly_category(entry.category), term)
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

return {
    check_word_match = check_word_match,
    score_match = score_match
}