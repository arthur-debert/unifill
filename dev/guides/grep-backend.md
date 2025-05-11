# Grep Backend for Unifill

This document describes the grep backend implementation for the Unifill plugin,
which provides an alternative way to search for Unicode characters using
external grep tools.

## Overview

The grep backend is designed to leverage the speed of external grep tools (like
ripgrep) for searching through Unicode character data. Unlike the lua and csv
backends that load all data into memory, the grep backend performs searches
directly on the text file, which can be more efficient for large datasets.

## Features

- **Fast Initialization**: The grep backend initializes very quickly since it
  doesn't need to load all data into memory.
- **External Tool Integration**: Uses ripgrep (or another configurable grep
  tool) for searching.
- **Multi-word Search**: Supports searching for multiple words, showing both
  exact phrase matches and individual word matches.
- **Case Insensitive**: Searches are case insensitive by default.

## Trade-offs

- **Search Speed vs. Accuracy**: While initialization is faster, actual searches
  may be slower than in-memory backends.
- **Ranking Limitations**: The grep backend doesn't support the same
  sophisticated ranking as the lua and csv backends.
- **Telescope Integration**: Uses Telescope's native FZY sorter instead of the
  custom sorter used by other backends.

## Implementation Details

The grep backend works by:

1. Creating a text file with Unicode data in a grep-friendly format
   (pipe-separated values).
2. Using ripgrep to search through this file when a query is entered.
3. Parsing the grep output to create entries that can be displayed in Telescope.

## Configuration

The grep backend can be configured in your Neovim config:

```lua
require('unifill').setup({
    backend = "grep",
    backends = {
        grep = {
            -- Path to the Unicode data text file
            data_path = "/path/to/unicode_data.txt",
            -- Command to use for grep (default: "rg" for ripgrep)
            grep_command = "rg"
        }
    }
})
```

## Performance Comparison

Based on benchmark results:

| Backend | Initialization | Search (avg)   |
| ------- | -------------- | -------------- |
| lua     | ~70-320 ms     | ~0.003-0.1 ms  |
| csv     | ~180-225 ms    | ~0.003-0.1 ms  |
| grep    | ~1-3 ms        | ~8-35 ms total |

The grep backend initializes about 100x faster than the other backends, but
searches are about 100x slower. This makes it ideal for situations where:

- You need to start up quickly
- You don't search frequently
- You're working with very large datasets where loading into memory would be
  problematic

## Implementation Notes

- The grep backend requires the text format of the Unicode data, which can be
  generated using `bin/fetch-data --format txt` or
  `bin/fetch-data --format all`.
- When Telescope is not available (e.g., in test environments), the backend
  gracefully falls back to returning empty results.
- Special characters in search queries are escaped to prevent grep syntax
  errors.

## Future Improvements

Potential improvements for the grep backend include:

1. Better ranking by using grep's context options to extract surrounding data
   for better scoring.
2. Parallel searches for multi-word queries to improve performance.
3. Caching frequently searched terms to improve response time.
4. Support for more advanced grep features like regex patterns.
