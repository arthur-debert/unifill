-- Theme configuration for unifill
local M = {}

-- UI configuration
M.ui = {
    -- Window layout
    layout = {
        width = 0.4,        -- 40% of screen width
        height = 0.4,       -- 40% of screen height
        previewer = false,  -- No previewer needed for Unicode chars
        prompt_title = "Unicode Characters",
        borderchars = {
            { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
            prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
            results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
            preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        },
    },
    
    -- Column configuration
    columns = {
        character = { width = 6 },   -- Unicode character (wider for visibility)
        name = { width = 30 },       -- Name
        details = { remaining = true }, -- Category and other info
    },
    
    -- Separator between columns
    separator = "   ", -- More spacing between columns
}

-- Highlight groups
M.highlights = {
    -- Define highlight groups for the Unicode characters
    character = "UnifillCharacter",
    name = "UnifillName",
    details = "UnifillDetails",
    match = "UnifillMatch",
}

-- Setup function to define highlight groups
function M.setup()
    -- Unicode character: bold and 100% black
    vim.api.nvim_command('highlight UnifillCharacter guifg=#000000 gui=bold')
    
    -- Other text: 80% black
    vim.api.nvim_command('highlight UnifillName guifg=#333333')
    vim.api.nvim_command('highlight UnifillDetails guifg=#333333')
    
    -- Match highlight: italic
    vim.api.nvim_command('highlight UnifillMatch gui=italic')
end

return M