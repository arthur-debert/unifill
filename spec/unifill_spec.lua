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

  it("can load and use unicode data", function()
    local unifill = require("unifill")
    local data = unifill._test.load_unicode_data()
    assert(type(data) == "table", "unicode data should be a table")
    assert(#data > 0, "unicode data table should not be empty")
    
    -- Verify first entry has the expected structure
    local first = data[1]
    assert(type(first) == "table", "data entry should be a table")
    assert(type(first.code_point) == "string", "entry should have code_point as string")
    assert(type(first.character) == "string", "entry should have character as string")
    assert(type(first.name) == "string", "entry should have name as string")
    assert(type(first.category) == "string", "entry should have category as string")
    assert(type(first.aliases) == "table", "entry should have aliases as table")
  end)

  describe("entry formatting", function()
    local unifill = require("unifill")
    local entry_maker = unifill._test.entry_maker

    -- Add entry_maker to test exports
    before_each(function()
      unifill._test.entry_maker = require("unifill")._test.entry_maker
    end)

    it("converts names to title case", function()
      local to_title_case = unifill._test.to_title_case
      assert.equals("Hello World", to_title_case("HELLO WORLD"))
      assert.equals("Right Arrow", to_title_case("RIGHT ARROW"))
      assert.equals("Em Dash", to_title_case("EM-DASH"))
    end)

    it("formats aliases correctly", function()
      local format_aliases = unifill._test.format_aliases
      assert.equals("", format_aliases({}))
      assert.equals(" (aka Right Arrow)", format_aliases({"RIGHT ARROW"}))
      assert.equals(" (aka Right Arrow, Forward)", format_aliases({"RIGHT ARROW", "FORWARD"}))
    end)

    it("provides friendly category names", function()
      local friendly_category = unifill._test.friendly_category
      assert.equals("Math Symbol", friendly_category("Sm"))
      assert.equals("Other Symbol", friendly_category("So"))
      assert.equals("Currency Symbol", friendly_category("Sc"))
    end)

    it("filters out control characters", function()
      local result = entry_maker({
        character = "",
        name = "NULL",
        code_point = "U+0000",
        category = "Cc",
        aliases = {}
      })
      assert.is_nil(result)
    end)

    it("formats display text correctly", function()
      local result = entry_maker({
        character = "→",
        name = "RIGHTWARDS ARROW",
        code_point = "U+2192",
        category = "Sm",
        aliases = {"RIGHT ARROW", "FORWARD"}
      })
      assert.equals(
        "→     Rightwards Arrow (aka Right Arrow, Forward) (Math Symbol)",
        result.display
      )
    end)
  end)
end)