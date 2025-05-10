-- Text formatting utilities for unifill

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

return {
    to_title_case = to_title_case,
    format_aliases = format_aliases,
    friendly_category = friendly_category
}