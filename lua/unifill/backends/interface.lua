-- Interface for data backends in unifill
-- This defines the common interface that all backends must implement

-- Interface definition
local BackendInterface = {
    -- Must return a table of entries with consistent structure
    -- Each entry should have:
    -- - name: The Unicode character name
    -- - character: The actual Unicode character
    -- - code_point: Unicode code point
    -- - category: Unicode category
    -- - aliases: Optional aliases (array of strings)
    load_data = function(self) end,
    
    -- Must return the structure of entries for validation
    get_entry_structure = function(self) end
}

return BackendInterface