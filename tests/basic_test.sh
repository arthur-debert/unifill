#!/bin/bash

# Basic test to verify headless Neovim execution
echo "Running basic Neovim test..."

# Run Neovim with a simple Lua command and capture output
OUTPUT=$(nvim --headless -c "lua print('Basic test successful')" -c "messages" -c q 2>&1)

# Check if the output contains our test message
if echo "$OUTPUT" | grep -q "Basic test successful"; then
    echo "✓ Basic test passed"
    exit 0
else
    echo "✗ Basic test failed"
    echo "Output was: $OUTPUT"
    exit 1
fi