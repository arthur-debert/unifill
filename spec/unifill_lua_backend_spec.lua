-- spec/unifill_lua_backend_spec.lua
-- Tests for the Lua backend implementation

describe("unifill lua backend", function()
    local LuaBackend
    
    before_each(function()
        -- Clear module cache
        package.loaded['unifill.backends.lua_backend'] = nil
        
        -- Load the lua backend
        LuaBackend = require("unifill.backends.lua_backend")
    end)
    
    after_each(function()
        -- Clear module cache
        package.loaded['unifill.backends.lua_backend'] = nil
    end)
    
    -- Test that the backend can be created with default configuration
    it("can be instantiated", function()
        local backend = LuaBackend.new()
        assert(backend ~= nil, "backend should not be nil")
    end)
    
    -- Test that the backend returns the expected entry structure definition
    it("returns the correct entry structure", function()
        local backend = LuaBackend.new()
        local structure = backend:get_entry_structure()
        
        assert(structure ~= nil, "structure should not be nil")
        assert(structure.name == "string", "name should be a string")
        assert(structure.character == "string", "character should be a string")
        assert(structure.code_point == "string", "code_point should be a string")
        assert(structure.category == "string", "category should be a string")
        assert(structure.aliases == "table", "aliases should be a table")
    end)
    
    -- Test that the backend reports its active status correctly
    it("reports correct active status", function()
        local backend = LuaBackend.new()
        assert(backend:is_active() == true, "Lua backend should be active")
    end)
    
    -- Test that the backend can load data
    it("can load data", function()
        local backend = LuaBackend.new()
        local data = backend:load_data()
        assert(type(data) == "table", "data should be a table")
        assert(#data > 0, "data should not be empty")

        -- Check first entry structure
        local entry = data[1]
        assert(type(entry.name) == "string", "entry.name should be a string")
        assert(type(entry.character) == "string", "entry.character should be a string")
        assert(type(entry.code_point) == "string", "entry.code_point should be a string")
        assert(type(entry.category) == "string", "entry.category should be a string")
        -- aliases can be nil or a table
        if entry.aliases then
            assert(type(entry.aliases) == "table", "entry.aliases should be a table if present")
        end
    end)
    
    -- Test that the backend can be configured through the unifill setup function
    it("can be configured through setup", function()
        local unifill = require("unifill")
        
        -- Save original config
        local original_backend = require("unifill.data").get_backend_name()
        
        -- Set up with lua backend and custom path
        local plugin_root = require("unifill.data").get_plugin_root()
        local constants = require("unifill.constants")
        unifill.setup({
            backend = "lua",
            backends = {
                lua = {
                    data_path = plugin_root .. "/data/unicode." .. constants.DATASET.EVERYDAY .. ".lua"
                }
            }
        })
        
        -- Verify the configuration was applied
        local backend_name = require("unifill.data").get_backend_name()
        assert(backend_name == "lua", "backend_name should be lua")
        
        -- Restore original config
        unifill.setup({ backend = original_backend })
    end)
end)