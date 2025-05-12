-- Interface for data backends in unifill
-- This defines the common interface that all backends must implement

-- Interface definition
local BackendInterface = {
    -- Flag to indicate if the backend is active and should be used
    -- Only active backends will be used in production and tests
    active = true,

    -- Must return a table of entries with consistent structure
    -- Each entry should have:
    -- - name: The Unicode character name
    -- - character: The actual Unicode character
    -- - code_point: Unicode code point
    -- - category: Unicode category
    -- - aliases: Optional aliases (array of strings)
    load_data = function(_) end,

    -- Must return the structure of entries for validation
    get_entry_structure = function(_) end,

    -- Must return whether the backend is active
    is_active = function(self)
        return self.active
    end
}
return BackendInterface