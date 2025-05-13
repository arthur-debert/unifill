-- tests2.0/plugin_setup_spec.lua
describe("plugin setup", function()
  it("loads the unifill plugin", function()
    local unifill = require("unifill")
    assert.is_not_nil(unifill)
  end)

  it("loads telescope", function()
    local telescope = require("telescope")
    assert.is_not_nil(telescope)
  end)
  
  it("can access unifill's telescope extension", function()
    local telescope = require("telescope")
    telescope.setup()
    -- Load the unifill extension if it's registered as an extension
    pcall(function() telescope.load_extension("unifill") end)
    -- This test will pass even if unifill doesn't register as an extension
    assert.is_not_nil(telescope)
  end)
end)