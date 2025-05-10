describe("unifill", function()
  before_each(function()
    -- Mock telescope modules before loading unifill
    _G.telescope = {
      pickers = {
        new = function() return { find = function() end } end
      },
      finders = {
        new_table = function() return {} end
      },
      config = { 
        values = {
          generic_sorter = function() return {} end
        }
      },
      actions = { 
        close = function() end,
        select_default = { replace = function() end }
      },
      actions_state = {
        get_selected_entry = function() return {} end
      }
    }
    package.loaded['telescope.pickers'] = telescope.pickers
    package.loaded['telescope.finders'] = telescope.finders
    package.loaded['telescope.config'] = telescope.config
    package.loaded['telescope.actions'] = telescope.actions
    package.loaded['telescope.actions.state'] = telescope.actions_state
  end)

  it("simple test", function()
    assert(true, "this test should pass")
  end)

  it("can load unifill module", function()
    local unifill = require("unifill")
    assert(type(unifill) == "table", "unifill module should be a table")
    assert(type(unifill.unifill) == "function", "unifill.unifill should be a function")
  end)

  it("attempts to load unicode data", function()
    local unifill = require("unifill")
    local data = unifill._test.load_unicode_data()
    assert(type(data) == "table", "unicode data should be a table")
  end)
end)