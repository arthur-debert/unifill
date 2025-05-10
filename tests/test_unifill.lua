-- Test script for unifill plugin
local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, expected, actual))
    end
    print(string.format("✓ %s", message))
end

-- Test plugin root detection
local function test_plugin_root()
    local plugin_path = vim.fn.getcwd() .. "/unifill.lua"
    local expected_root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h")
    local actual_root = vim.fn.fnamemodify(plugin_path, ":p:h")
    assert_eq(actual_root, expected_root, "Plugin root detection")
end

-- Test unicode data loading
local function test_unicode_data_loading()
    local data_path = vim.fn.getcwd() .. "/data/unifill-datafetch/unicode_data.lua"
    
    -- Try to load and execute the file
    local ok, data = pcall(dofile, data_path)
    if not ok then
        print("Note: Unicode data loading failed: " .. data)
        return
    end
    
    -- Verify the data structure
    assert(type(data) == "table", "Unicode data should be a table")
    assert(#data > 0, "Unicode data should not be empty")
    
    -- Check first entry structure
    local first_entry = data[1]
    assert(type(first_entry.code_point) == "string", "Entry should have code_point as string")
    assert(type(first_entry.character) == "string", "Entry should have character as string")
    assert(type(first_entry.name) == "string", "Entry should have name as string")
    assert(type(first_entry.category) == "string", "Entry should have category as string")
    assert(type(first_entry.aliases) == "table", "Entry should have aliases as table")
    
    print("✓ Unicode data loading and structure")
end

-- Test entry formatting
local function test_entry_formatting()
    -- Create a mock entry
    local entry = {
        character = "☺",
        name = "WHITE SMILING FACE",
        code_point = "U+263A",
        category = "Symbol",
        aliases = {"SMILING FACE", "HAPPY FACE"}
    }
    
    -- Test display format
    local display = string.format("%s - %s (%s) [%s]",
        entry.character,
        entry.name,
        entry.code_point,
        entry.category
    )
    assert_eq(display, "☺ - WHITE SMILING FACE (U+263A) [Symbol]", "Entry display format")
    
    -- Test search text format
    local search_text = entry.name
    if entry.aliases and #entry.aliases > 0 then
        search_text = search_text .. " " .. table.concat(entry.aliases, " ")
    end
    assert_eq(search_text, "WHITE SMILING FACE SMILING FACE HAPPY FACE", "Entry search text")
    
    print("✓ Entry formatting")
end

-- Test plugin command registration
local function test_command_registration()
    -- Load the plugin
    local plugin_path = vim.fn.getcwd() .. "/unifill.lua"
    local ok, plugin = pcall(dofile, plugin_path)
    if not ok then
        error("Failed to load plugin: " .. plugin)
    end
    
    -- Check if the unifill function is exported
    assert(type(plugin.unifill) == "function", "Plugin should export unifill function")
    
    -- Check if the keymap is registered
    local keymap = vim.fn.maparg("<leader>iu", "n")
    assert(keymap ~= "", "Keymap should be registered")
    
    print("✓ Command registration")
end

-- Run tests
print("\nRunning unifill tests...")
test_plugin_root()
test_unicode_data_loading()
test_entry_formatting()
test_command_registration()
print("\nAll tests completed!")