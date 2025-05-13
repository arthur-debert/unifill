-- tests2.0/telescope_picker_spec.lua
describe("telescope integration", function()
  it("can create a telescope picker", function()
    -- Require telescope modules
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    
    -- Create a basic picker
    local picker = pickers.new({}, {
      prompt_title = "Test Picker",
      finder = finders.new_table({
        results = {"item1", "item2", "item3"}
      }),
      sorter = conf.generic_sorter({}),
    })
    
    -- Verify the picker was created
    assert.is_not_nil(picker)
    assert.equals("Test Picker", picker.prompt_title)
  end)
  
  it("can access unifill's telescope integration", function()
    -- Require unifill's telescope module
    local unifill_telescope = require("unifill.telescope")
    
    -- Verify it exists
    assert.is_not_nil(unifill_telescope)
    
    -- Verify it has the expected functions
    assert.is_function(unifill_telescope.custom_sorter)
    assert.is_function(unifill_telescope.entry_maker)
  end)
  
  it("can create a unifill-like picker", function()
    -- Require telescope modules
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local unifill_telescope = require("unifill.telescope")
    
    -- Create test data similar to unicode data
    local test_data = {
      {
        character = "→",
        name = "RIGHTWARDS ARROW",
        code_point = "U+2192",
        category = "Sm",
        aliases = {"RIGHT ARROW"}
      },
      {
        character = "←",
        name = "LEFTWARDS ARROW",
        code_point = "U+2190",
        category = "Sm",
        aliases = {"LEFT ARROW"}
      }
    }
    
    -- Create a picker similar to unifill's picker
    local picker = pickers.new({}, {
      prompt_title = "Test Unicode Picker",
      finder = finders.new_table({
        results = test_data,
        entry_maker = unifill_telescope.entry_maker
      }),
      sorter = unifill_telescope.custom_sorter({}),
    })
    
    -- Verify the picker was created
    assert.is_not_nil(picker)
    assert.equals("Test Unicode Picker", picker.prompt_title)
  end)
end)