# How to work with the unifill project

This document outlines the key guidelines and resources for working with the
unifill project, a Telescope-based Neovim plugin for inserting Unicode
characters.

## Project Documentation

The main project documentation can be found in [README.txt](../../README.txt),
which covers:

- Basic plugin description and usage
- Installation instructions
- Dataset generation and management
- Development setup and testing

## External Documentation

The project leverages Telescope for its UI. The developer documentation is
maintained in the `tmp` directory (not under source control):

- [Telescope Developer Guide](../../tmp/telescope-developers.md) - For
  understanding the Telescope extension architecture

## Development Guidelines

1. **Code Changes**

   - All code changes must be accompanied by corresponding tests
   - Tests should verify both functionality and edge cases
   - Use the plenary.nvim testing framework (see spec/ directory)

2. **Testing**

   - Run tests locally before submitting changes: `bin/run-tests`
   - Tests are automatically run via GitHub Actions on push/PR
   - Test files should follow the plenary test format

3. **Dataset Management**

   - The Unicode dataset is stored as a Lua lookup table for performance
   - Generate updated dataset using `bin/fetch-data`
   - Dataset changes should be tested thoroughly

4. **Documentation**

   - Keep README.txt updated with any user-facing changes
   - Note that the README.txt is txxt formatted, not markdown. Just follow the
     file's convention, but do not format this as markdown.
   - Document new features and configuration options
   - Update development docs when changing core functionality

5. **File Layout**

```text
├── README.txt -> keep updated and read it. txxt, not markdown.
├── bin
│   ├── fetch-data -> calls the script to gen the dataset and places it in data.
│   └── run-tests -> run tests, used all the timed, hopefully.
├── data
│   └── glyph-catcher -> data set
├── dev -> dev oriented information
│   └── rules -> rules for coding assistant (this doc)
├── lua
│   └── unifill -> plugin source code
│       ├── init.lua -> main entry point and plugin setup
│       ├── data.lua -> data loading functionality
│       ├── format.lua -> text formatting utilities
│       ├── search.lua -> search scoring and matching
│       ├── telescope.lua -> telescope integration
│       ├── log.lua -> logging functionality
│       └── backends -> data backend implementations
│           ├── interface.lua -> backend interface definition
│           ├── lua_backend.lua -> Lua table backend
│           ├── csv_backend.lua -> CSV file backend
│           ├── grep_backend.lua -> Grep-based backend
│           └── fast_grep_backend.lua -> Optimized grep backend
├── spec -> .plenary tests
├── glyph-catcher -> python fetcher for the dataset.
│   └── src
│       └── setup_dataset.py -> .the main file.
└── unifill.lua -> legacy entry point (deprecated)
```

## Module Structure

The plugin's code is organized into these logical components:

- **init.lua**: Main entry point, exports public API, handles plugin setup
- **data.lua**: Handles loading and processing of Unicode data
- **format.lua**: Text formatting utilities for display
- **search.lua**: Search algorithm implementation
- **telescope.lua**: Telescope picker integration and UI
- **log.lua**: Logging functionality for debugging
- **backends/**: Data backend implementations
  - **interface.lua**: Defines the common interface for all backends
  - **lua_backend.lua**: Implements the Lua table backend
  - **csv_backend.lua**: Implements the CSV file backend
  - **grep_backend.lua**: Implements the grep-based backend
  - **fast_grep_backend.lua**: Implements the optimized grep backend

Each module has a specific responsibility and exports only the necessary
functions. This separation makes the code more maintainable and easier to test.

## Logging

The plugin uses plenary.nvim's logger for debugging:

- Logs are stored in `<projectRoot>/tmp/logs/unifill.log`
- The `tmp` directory is not under source control
- Log levels include: DEBUG, INFO, WARN, ERROR
- Each log entry includes:
  - Log level
  - Timestamp
  - Source file and line number
  - Message content

### Log Level Configuration

The log level can be configured using the `UNIFILL_LOG_LEVEL` environment
variable:

```bash
# Set log level to debug to see all messages
UNIFILL_LOG_LEVEL=debug nvim

# Set log level to error to see only error messages
UNIFILL_LOG_LEVEL=error nvim
```

Default log level is "info" if not specified.

### Viewing Logs

To view logs:

```bash
cat tmp/logs/unifill.log
```

To monitor logs in real-time:

```bash
tail -f tmp/logs/unifill.log
```

### Important Log Messages

When debugging Telescope integration issues, pay special attention to:

- Scoring function logs (prefixed with "TELESCOPE SCORING")
- Search matching logs (prefixed with "START SCORING")
- Entry creation logs

The log file is cleared on each plugin initialization to prevent it from growing
too large.
