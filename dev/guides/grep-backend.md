# Grep Backends for Unifill

This document describes the grep backend implementations for the Unifill plugin,
which provide alternative ways to search for Unicode characters using
external grep tools.

## Overview

The grep backends are designed to leverage the speed of external grep tools (like
ripgrep) for searching through Unicode character data. Unlike the lua and csv
backends that load all data into memory, the grep backends perform searches
directly on the text file, which can be more efficient for large datasets.

There are two grep backend implementations:
1. **grep_backend**: The standard grep backend that performs more processing in Lua
2. **fast_grep_backend**: An optimized version that minimizes Lua processing

## Features
## Features

### Common Features

- **Fast Initialization**: Both grep backends initialize very quickly since they
  don't need to load all data into memory.
- **External Tool Integration**: Use ripgrep (or another configurable grep
  tool) for searching.
- **Case Insensitive**: Searches are case insensitive by default.

### Standard Grep Backend

- **Multi-word Search**: Supports searching for multiple words, showing both
  exact phrase matches and individual word matches.
- **Detailed Entry Parsing**: Parses grep output into full entry structures.

### Fast Grep Backend

- **Minimal Processing**: Performs minimal Lua processing to maximize performance.
- **Direct Telescope Integration**: Leverages Telescope's native capabilities more directly.
- **Optimized Entry Creation**: Creates simplified entry structures with only essential fields.
## Trade-offs
## Trade-offs

### Standard Grep Backend

- **Search Speed vs. Accuracy**: While initialization is faster, actual searches
  may be slower than in-memory backends.
- **Ranking Limitations**: Doesn't support the same sophisticated ranking as the lua and csv backends.
- **Telescope Integration**: Uses Telescope's native FZY sorter instead of the
  custom sorter used by other backends.

### Fast Grep Backend

- **Slightly Higher Initialization**: Slightly higher initialization time than the standard grep backend,
  but still much faster than in-memory backends.
- **Improved Search Performance**: Better search performance than the standard grep backend.
- **Simplified Entry Structure**: Less detailed entry information, but faster processing.
## Implementation Details

### Standard Grep Backend

The standard grep backend works by:

1. Creating a text file with Unicode data in a grep-friendly format
   (pipe-separated values).
2. Using ripgrep to search through this file when a query is entered.
3. Parsing the grep output to create detailed entries that can be displayed in Telescope.
4. Processing multi-word searches with special handling.

### Fast Grep Backend

The fast grep backend works by:

1. Using the same text file format as the standard grep backend.
2. Minimizing Lua processing by leveraging Telescope's native capabilities.
3. Creating simplified entry structures with only essential fields.
4. Optimizing the entry maker function to reduce processing overhead.

## Configuration
## Configuration

Both grep backends can be configured in your Neovim config:

```lua
require('unifill').setup({
    backend = "grep",  -- or "fast_grep"
    backends = {
        grep = {
            -- Path to the Unicode data text file
            data_path = "/path/to/unicode_data.txt",
            -- Command to use for grep (default: "rg" for ripgrep)
            grep_command = "rg"
        },
        fast_grep = {
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

| Backend   | Initialization | Search (avg)     |
| --------- | -------------- | ---------------- |
| lua       | ~70-320 ms     | ~0.003-0.1 ms    |
| csv       | ~180-225 ms    | ~0.003-0.1 ms    |
| grep      | ~0.3-1 ms      | ~6-15 ms total   |
| fast_grep | ~7 ms          | ~5-6 ms total    |

The grep backends initialize about 100x faster than the in-memory backends, but
searches are slower. The fast_grep backend provides a good balance between
initialization speed and search performance. This makes grep backends ideal for situations where:

- You need to start up quickly
- You don't search frequently
- You're working with very large datasets where loading into memory would be
  problematic

## Implementation Notes

- Both grep backends require the text format of the Unicode data, which can be
  generated using `bin/fetch-data --format txt` or
  `bin/fetch-data --format all`.
- When Telescope is not available (e.g., in test environments), the backends
  gracefully fall back to returning empty results.
- Special characters in search queries are escaped to prevent grep syntax
  errors.
- The fast_grep backend uses a more direct integration with Telescope's finder
  and entry maker system.

## Future Improvements

Potential improvements for the grep backends include:

1. Better ranking by using grep's context options to extract surrounding data
   for better scoring.
2. Parallel searches for multi-word queries to improve performance.
3. Caching frequently searched terms to improve response time.
4. Support for more advanced grep features like regex patterns.
5. Further optimizations to the fast_grep backend to reduce processing overhead.
6. Hybrid approach that combines the speed of grep with the ranking capabilities
   of in-memory backends.
