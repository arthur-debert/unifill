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

  describe("search functionality", function()
    local unifill = require("unifill")
    local score_match = unifill._test.score_match
    
    it("scores matches by location priority", function()
      -- Test entry with match in name (highest priority)
      local name_match = score_match({
        name = "RIGHTWARDS ARROW",
        category = "Other Symbol",
        aliases = {"FORWARD"}
      }, {"right"})
      
      -- Test entry with match in alias (medium priority)
      local alias_match = score_match({
        name = "ARROW POINTING RIGHT",
        category = "Other Symbol",
        aliases = {"RIGHTWARDS"}
      }, {"right"})
      
      -- Test entry with match in category (lowest priority)
      local category_match = score_match({
        name = "PLUS SIGN",
        category = "Math Symbol",
        aliases = {"ADD"}
      }, {"math"})

      assert(name_match > alias_match, "Name matches should score higher than alias matches")
      assert(alias_match > category_match, "Alias matches should score higher than category matches")
    end)

    it("requires full term matches", function()
      local entry = {
        name = "RIGHTWARDS ARROW",
        category = "Math Symbol",
        aliases = {"RIGHT ARROW"}
      }

      -- Should match full terms
      local full_match = score_match(entry, {"right", "arrow"})
      assert(full_match > 0, "Should match full terms")

      -- Should not match partial terms
      local partial_match = score_match(entry, {"ma", "th"})
      assert(partial_match == 0, "Should not match partial terms")
    end)

    it("scores higher for multiple term matches", function()
      local entry = {
        name = "RIGHTWARDS ARROW",
        category = "Math Symbol",
        aliases = {"RIGHT ARROW"}
      }

      local single_match = score_match(entry, {"right"})
      local double_match = score_match(entry, {"right", "arrow"})
      local triple_match = score_match(entry, {"right", "arrow", "math"})

      assert(double_match > single_match, "Multiple term matches should score higher")
      assert(triple_match > double_match, "More matching terms should score even higher")
    end)

    it("matches case insensitively", function()
      local entry = {
        name = "RIGHTWARDS ARROW",
        category = "Math Symbol",
        aliases = {"RIGHT ARROW"}
      }

      local upper_score = score_match(entry, {"RIGHT"})
      local lower_score = score_match(entry, {"right"})
      local mixed_score = score_match(entry, {"RiGhT"})

      assert.equals(upper_score, lower_score, "Upper and lowercase searches should score the same")
      assert.equals(upper_score, mixed_score, "Mixed case searches should score the same")
    end)
  end)
end)