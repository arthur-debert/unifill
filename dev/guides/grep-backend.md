# Creating a Telescope-Native Grep Backend for Unifill

After analyzing the unifill codebase and Telescope's architecture, I've
developed a comprehensive assessment and proposal for implementing a grep-based
backend that leverages Telescope's native fuzzy finding capabilities.

## 1. Assessment of Telescope's Search and Ranking Capabilities

### Telescope's Fuzzy Finding System

Telescope provides several sorters (ranking mechanisms):

1. **Generic Fuzzy Sorter** (`sorters.get_generic_fuzzy_sorter`): Uses n-gram
   matching to score results
2. **File Fuzzy Sorter** (`sorters.get_fuzzy_file`): Similar to generic but
   optimized for file paths
3. **FZY Sorter** (`sorters.get_fzy_sorter`): Uses the FZY algorithm, which can
   be backed by a native C implementation
4. **Levenshtein Sorter** (`sorters.get_levenshtein_sorter`): Uses edit distance
   (not recommended for performance)

Telescope's sorters work by:

- Assigning a score to each entry based on how well it matches the search query
- Lower scores are better (closer matches)
- Scores below 0 filter out entries entirely

### Telescope's Finder System

Telescope offers several finder types:

- `new_table`: For static in-memory data
- `new_oneshot_job`: For command execution that completes and returns all
  results
- `new_async_job`: For long-running commands that stream results

### Current Unifill Ranking System

Unifill's current ranking system in `search.lua`:

- Prioritizes matches in this order: name > alias > category
- Assigns vastly different scores to matches in different fields
- Requires normalized data with consistent structure

## 2. Proposed Grep Backend Implementation

### Core Concept

Create a backend that:

1. Uses `ripgrep` (or similar) to search through a specially formatted text file
2. Leverages Telescope's native sorters for fuzzy matching
3. Preserves enough information to maintain most of the ranking priorities

### Data Format

I propose creating a specially formatted text file where each line contains:

```
<character>|<name>|<code_point>|<category>|<alias1>|<alias2>|...
```

For example:

```
→|RIGHTWARDS ARROW|2192|Sm|FORWARD|RIGHT ARROW
```

This format:

- Is easily searchable with grep-like tools
- Preserves all necessary information
- Can be generated from the existing dataset

### Implementation Approach

1. **Data Generation**:

   - Modify `unifill-datafetch/src/setup_dataset.py` to generate a grep-friendly
     format
   - Store in `data/unifill-datafetch/unicode_data.txt`

2. **Backend Implementation**:

   - Create a new backend similar to existing ones but optimized for grep
   - Use Telescope's `new_async_job` finder to execute grep commands
   - Parse the grep output to create entries compatible with the existing system

3. **Integration with Telescope**:
   - Modify `telescope.lua` to use Telescope's native sorter when using the grep
     backend
   - Create a custom entry maker that parses the grep output format

### Ranking Strategy

Since we can't fully replicate the current ranking system with grep alone, I
propose:

1. **Field-Weighted Format**:

   - Format the data file to give more weight to name matches
   - For example:
     `<character>|<name>|<name>|<name>|<code_point>|<category>|<aliases>`
   - This repeats the name field multiple times so grep matches on name are more
     likely

2. **Post-Processing Ranking**:
   - After grep returns results, apply a simplified version of the current
     ranking
   - This would be less computationally intensive since we're only ranking a
     subset of data

## 3. Feature Parity Analysis

### What We Can Maintain

1. **Basic Functionality**: Finding and inserting Unicode characters
2. **Search by Name/Alias/Category**: All fields are searchable
3. **Display Format**: Same display format in results

### What We Would Lose

1. **Exact Ranking Algorithm**: The precise scoring based on field priority
   would be approximated
2. **Multi-Term Scoring**: Telescope's native sorters handle multi-term searches
   differently

### What We Would Gain

1. **Speed**: Potentially much faster for large datasets
2. **Memory Efficiency**: No need to load the entire dataset into memory
3. **Native Integration**: Better integration with Telescope's native
   capabilities

## 4. Compromise Solution

I propose a hybrid approach:

1. **Two-Stage Search**:

   - First stage: Use grep to quickly filter the dataset
   - Second stage: Apply a simplified version of the current ranking to the
     filtered results

2. **Configurable Ranking**:

   - Allow users to choose between "fast" mode (pure grep) and "accurate" mode
     (grep + post-processing)

3. **Data Format Optimization**:
   - Generate the data file in a format that naturally biases toward the desired
     ranking
   - Include metadata that can be used for post-processing ranking

```lua
-- Example configuration
require('unifill').setup({
    backend = "grep",
    backends = {
        grep = {
            data_path = "/path/to/unicode_data.txt",
            ranking_mode = "fast", -- or "accurate"
            grep_command = "rg",   -- or "grep", "ag", etc.
        }
    }
})
```

## 5. Data Generation Recommendations

To optimize the grep backend, I recommend:

1. **Multiple Data Formats**:

   - Generate both the current formats (lua, csv) and the new grep-friendly
     format
   - Allow users to choose based on their needs

2. **Field Weighting**:

   - Structure the grep data file to naturally bias toward the desired ranking
   - For example, include the name field multiple times or with special markers

3. **Indexing**:
   - Consider creating multiple indexed files for different search patterns
   - For example, one file optimized for name searches, another for category
     searches

## Conclusion

A grep-based backend for unifill is feasible and could offer significant
performance benefits. While it can't perfectly replicate the current ranking
system, a thoughtful implementation can provide a good compromise between speed
and feature parity.

The proposed solution offers users flexibility to choose between backends based
on their specific needs, whether they prioritize perfect ranking or maximum
performance.
