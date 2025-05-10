# Unifill Plugin Tests

This directory contains tests for the Unifill Neovim plugin. The tests are designed to run headlessly and verify core plugin functionality.

## Test Structure

- [`basic_test.sh`](tests/basic_test.sh) - Verifies basic headless Neovim execution
- [`test_unifill.lua`](tests/test_unifill.lua) - Main plugin test suite
- [`run_tests.sh`](tests/run_tests.sh) - Test runner script

## Running Tests

To run all tests:

```bash
./tests/run_tests.sh
```

## Test Coverage

The test suite verifies:

1. Plugin Root Detection
   - Confirms correct plugin directory resolution

2. Unicode Data Loading
   - Tests data module loading mechanism
   - Handles expected module not found case

3. Entry Formatting
   - Verifies character display formatting
   - Tests search text generation with aliases
   - Validates entry structure

4. Command Registration
   - Confirms plugin function export
   - Verifies keymapping registration

## Expected Output

A successful test run will show:

```
Running unifill tests...
✓ Plugin root detection
Note: Unicode data loading failed as expected (module not found)
✓ Entry display format
✓ Entry search text
✓ Entry formatting
✓ Command registration
All tests completed!
```

Note: The "module not found" message for unicode data loading is expected when running tests without the full dataset installed.