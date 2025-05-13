# Unifill Test Suite 2.0

This directory contains a comprehensive test suite for the Unifill plugin,
focusing on validating the testing approach described in the
[testing guide](../dev/guides/testing.md).

## Test Structure

The test suite is organized into several test files, each focusing on a specific
aspect of testing:

1. **Basic Setup**

   - `plugin_setup_spec.lua`: Tests for loading the plugin and its dependencies
   - `test_init.lua`: Initialization file for the test environment

2. **Buffer Operations**

   - `buffer_operations_spec.lua`: Tests for basic buffer operations

3. **Command Mode**

   - `command_mode_spec.lua`: Tests for executing Vim commands

4. **Keypress Simulation**

   - `keypress_simulation_spec.lua`: Tests for simulating keypresses

5. **Asynchronous Operations**

   - `async_operations_spec.lua`: Tests for handling asynchronous operations

6. **Telescope Integration**
   - `telescope_picker_spec.lua`: Tests for creating and using Telescope pickers
   - `telescope_actions_spec.lua`: Tests for Telescope actions

## Running the Tests

To run the tests, use the provided `run-tests` script:

```bash
./tests2.0/run-tests
```

This script will:

1. Install the necessary dependencies using Lazy.nvim
2. Run all the tests using Plenary's test runner

## Test Environment

The tests run in a headless Neovim instance with a minimal configuration defined
in `test_init.lua`. This configuration:

- Sets up Lazy.nvim for plugin management
- Loads Plenary for testing
- Configures the runtime path to include the current project
- Sets appropriate environment variables for testing

## Adding New Tests

When adding new tests:

1. Create a new file with the `_spec.lua` suffix
2. Follow the Plenary test format with `describe` and `it` blocks
3. Use appropriate assertions from Plenary's assertion library
4. Make sure to clean up any resources created during tests

## Debugging Tests

If tests fail, check:

1. The error messages in the test output
2. The log files in `tmp/logs/`
3. Make sure all dependencies are properly installed
4. Verify that the test environment is correctly set up

## Test Coverage

The current test suite covers:

- Plugin loading and initialization
- Buffer operations and manipulations
- Command execution
- Keypress simulation
- Asynchronous operations
- Telescope integration (pickers and actions)
- Unicode character insertion
