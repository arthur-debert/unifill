-- This is an invalid Lua file for testing
local function test()
  return "Missing end parenthesis"
end

-- Syntax error below (missing closing brace)
return {
  test = test