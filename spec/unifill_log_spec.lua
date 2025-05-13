-- spec/unifill_log_spec.lua
describe("unifill.log", function()
  before_each(function()
    -- Clear module cache
    package.loaded['unifill.log'] = nil
    
    -- Ensure test environment variables are set
    vim.env.PLENARY_TEST = "1"
    -- Set log level from environment variable or default to error
    vim.env.UNIFILL_LOG_LEVEL = vim.env.UNIFILL_LOG_LEVEL or "error"
  end)

  after_each(function()
    -- Clear module cache
    package.loaded['unifill.log'] = nil
  end)

  it("can load and use logger", function()
    local log = require("unifill.log")
    assert.is_table(log, "log module should be a table")
    assert.is_function(log.debug, "log.debug should be a function")
    assert.is_function(log.info, "log.info should be a function")
    assert.is_function(log.warn, "log.warn should be a function")
    assert.is_function(log.error, "log.error should be a function")

    -- Test logging (this should not throw errors)
    log.debug("Test debug message")
    log.info("Test info message")
    log.warn("Test warning message")
    log.error("Test error message")

    -- Test logging with tables
    log.debug("Test table logging", {
      key = "value",
      nested = {
        inner = true
      }
    })

    -- Test multiple arguments
    log.info("Multiple", "arguments", "test")
  end)
end)