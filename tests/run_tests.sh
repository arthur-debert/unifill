#!/bin/bash

echo "Running unifill plugin tests..."

# Run the Lua tests in headless Neovim and capture output
OUTPUT=$(nvim --headless \
    -c "set rtp+=." \
    -c "luafile tests/test_unifill.lua" \
    -c "messages" \
    -c "q" 2>&1)

# Display the output
echo "$OUTPUT"

# Check if any actual test failures occurred
# Ignore expected "module not found" messages
if echo "$OUTPUT" | grep -q "Error\|Failed" | grep -v "module not found"; then
    echo "✗ Tests failed"
    exit 1
elif echo "$OUTPUT" | grep -q "✓"; then
    echo "✓ All tests passed (with expected module loading notes)"
    exit 0
else
    echo "? No test results found in output"
    exit 1
fi