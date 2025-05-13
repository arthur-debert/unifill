-- Tests for the unifill backends system
local eq = assert.are.same

describe("unifill backends", function()
    -- Load modules
    local interface = require("unifill.backends.interface")
    local LuaBackend = require("unifill.backends.lua_backend")
    local data_manager = require("unifill.data")

    describe("interface", function()
        it("has required methods", function()
            eq(type(interface.load_data), "function", "load_data should be a function")
            eq(type(interface.get_entry_structure), "function", "get_entry_structure should be a function")
        end)
    end)

    describe("lua_backend", function()
        local backend

        before_each(function()
            backend = LuaBackend.new()
        end)

        it("implements the interface", function()
            eq(type(backend.load_data), "function", "load_data should be a function")
            eq(type(backend.get_entry_structure), "function", "get_entry_structure should be a function")
            eq(type(backend.is_active), "function", "is_active should be a function")
        end)

        it("returns the expected entry structure", function()
            local structure = backend:get_entry_structure()
            eq(structure.name, "string", "name should be a string")
            eq(structure.character, "string", "character should be a string")
            eq(structure.code_point, "string", "code_point should be a string")
            eq(structure.category, "string", "category should be a string")
            eq(structure.aliases, "table", "aliases should be a table")
        end)

        it("reports correct active status", function()
            eq(backend:is_active(), true, "Lua backend should be active")
        end)

        -- Only run data loading tests for active backends
        if backend:is_active() then
            it("can load data", function()
                local data = backend:load_data()
                assert.is_table(data, "data should be a table")
                assert.is_true(#data > 0, "data should not be empty")

                -- Check first entry structure
                local entry = data[1]
                assert.is_string(entry.name, "entry.name should be a string")
                assert.is_string(entry.character, "entry.character should be a string")
                assert.is_string(entry.code_point, "entry.code_point should be a string")
                assert.is_string(entry.category, "entry.category should be a string")
                -- aliases can be nil or a table
                if entry.aliases then
                    assert.is_table(entry.aliases, "entry.aliases should be a table if present")
                end
            end)
        end
    end)

    describe("csv_backend", function()
        local CSVBackend = require("unifill.backends.csv_backend")
        local backend

        before_each(function()
            backend = CSVBackend.new()
        end)

        it("implements the interface", function()
            eq(type(backend.load_data), "function", "load_data should be a function")
            eq(type(backend.get_entry_structure), "function", "get_entry_structure should be a function")
            eq(type(backend.is_active), "function", "is_active should be a function")
        end)

        it("returns the expected entry structure", function()
            local structure = backend:get_entry_structure()
            eq(structure.name, "string", "name should be a string")
            eq(structure.character, "string", "character should be a string")
            eq(structure.code_point, "string", "code_point should be a string")
            eq(structure.category, "string", "category should be a string")
            eq(structure.aliases, "table", "aliases should be a table")
        end)

        it("reports correct active status", function()
            eq(backend:is_active(), false, "CSV backend should be inactive")
        end)

        -- Only run data loading tests for active backends
        if backend:is_active() then
            it("can load data", function()
                local data = backend:load_data()
                assert.is_table(data, "data should be a table")
                assert.is_true(#data > 0, "data should not be empty")

                -- Check first entry structure
                local entry = data[1]
                assert.is_string(entry.name, "entry.name should be a string")
                assert.is_string(entry.character, "entry.character should be a string")
                assert.is_string(entry.code_point, "entry.code_point should be a string")
                assert.is_string(entry.category, "entry.category should be a string")
                -- aliases can be nil or a table
                if entry.aliases then
                    assert.is_table(entry.aliases, "entry.aliases should be a table if present")
                end
            end)
        end
    end)

    describe("data_manager", function()
        it("has setup function", function()
            eq(type(data_manager.setup), "function", "setup should be a function")
        end)

        it("has load_unicode_data function", function()
            eq(type(data_manager.load_unicode_data), "function", "load_unicode_data should be a function")
        end)

        it("can load data with default config", function()
            -- Reset to default config
            data_manager.setup()

            local data = data_manager.load_unicode_data()
            assert.is_table(data, "data should be a table")
            assert.is_true(#data > 0, "data should not be empty")
        end)

        it("can be configured", function()
            -- Configure with custom path
            local plugin_root = data_manager.get_plugin_root()
            local constants = require("unifill.constants")
            data_manager.setup({
                backend = "lua",
                dataset = constants.DATASET.EVERYDAY,
                backends = {
                    lua = {
                        data_path = plugin_root .. "/data/unicode." .. constants.DATASET.EVERYDAY .. ".lua"
                    }
                }
            })

            local data = data_manager.load_unicode_data()
            assert.is_table(data, "data should be a table")
            assert.is_true(#data > 0, "data should not be empty")
        end)
    end)

    describe("integration", function()
        it("works with the existing system", function()
            -- Get data through the data manager
            local data1 = data_manager.load_unicode_data()

            -- Get data directly through the backend
            local constants = require("unifill.constants")
            local backend = LuaBackend.new({dataset = constants.DATASET.EVERYDAY})
            local data2 = backend:load_data()

            -- Both should return the same number of entries
            eq(#data1, #data2, "data manager and backend should return the same number of entries")

            -- Check a few entries to ensure they're the same
            for i = 1, math.min(10, #data1) do
                eq(data1[i].name, data2[i].name, "entry names should match")
                eq(data1[i].character, data2[i].character, "characters should match")
                eq(data1[i].code_point, data2[i].code_point, "code points should match")
                eq(data1[i].category, data2[i].category, "categories should match")
            end
        end)

        it("checks backend active status", function()
            -- Get all backend modules
            local LuaBackend = require("unifill.backends.lua_backend")
            local CSVBackend = require("unifill.backends.csv_backend")
            local GrepBackend = require("unifill.backends.grep_backend")
            local FastGrepBackend = require("unifill.backends.fast_grep_backend")
            
            -- Create instances
            local lua_backend = LuaBackend.new()
            local csv_backend = CSVBackend.new()
            local grep_backend = GrepBackend.new()
            local fast_grep_backend = FastGrepBackend.new()
            
            -- Check active status
            eq(lua_backend:is_active(), true, "Lua backend should be active")
            eq(csv_backend:is_active(), false, "CSV backend should be inactive")
            eq(grep_backend:is_active(), false, "Grep backend should be inactive")
            eq(fast_grep_backend:is_active(), false, "Fast grep backend should be inactive")
        end)

        it("only loads data from active backends", function()
            -- Configure data manager to use Lua backend (active)
            data_manager.setup({
                backend = "lua"
            })
            local lua_data = data_manager.load_unicode_data()
            
            -- Lua backend should return data
            assert.is_table(lua_data, "lua_data should be a table")
            assert.is_true(#lua_data > 0, "lua_data should not be empty")
            
            -- Reset to default backend
            data_manager.setup()
        end)

        it("exports setup and test functions", function()
            -- Mock the telescope modules to avoid errors when loading unifill
            package.loaded["telescope.pickers"] = {}
            package.loaded["telescope.finders"] = {}
            package.loaded["telescope.actions"] = {}
            package.loaded["telescope.actions.state"] = {}
            package.loaded["telescope.themes"] = {}
            package.loaded["telescope.config"] = {
                values = {}
            }
            package.loaded["telescope.pickers.entry_display"] = {}

            -- Now we can safely require unifill
            local unifill = require("unifill")

            -- Setup should be available
            eq(type(unifill.setup), "function", "setup should be a function")

            -- Test exports are still available
            eq(type(unifill._test.load_unicode_data), "function", "load_unicode_data should be exported")

            -- Clean up mocks
            package.loaded["telescope.pickers"] = nil
            package.loaded["telescope.finders"] = nil
            package.loaded["telescope.actions"] = nil
            package.loaded["telescope.actions.state"] = nil
            package.loaded["telescope.themes"] = nil
            package.loaded["telescope.config"] = nil
            package.loaded["telescope.pickers.entry_display"] = nil
        end)
    end)
end)
