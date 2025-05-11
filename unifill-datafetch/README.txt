UNIFILL-DATAFETCH
================

This project downloads and processes Unicode character data from multiple sources
to create a comprehensive dataset for the Unifill Neovim plugin. The dataset
includes character code points, actual characters, official names, categories,
and various aliases.

DATA SOURCES
-----------

The script fetches and processes data from the following sources:

1. UnicodeData.txt
   - Source: Unicode Character Database (UCD)
   - Content: Primary character information including code points, official names,
     and general categories
   - URL: https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt

2. NameAliases.txt
   - Source: Unicode Character Database (UCD)
   - Content: Formal aliases for characters, including corrections, control codes,
     and alternative names
   - URL: https://www.unicode.org/Public/UCD/latest/ucd/NameAliases.txt

3. NamesList.txt
   - Source: Unicode Character Database (UCD)
   - Content: Informative aliases, cross-references, and notes about characters
   - URL: https://www.unicode.org/Public/UCD/latest/ucd/NamesList.txt
   - Format: Contains entries like "= z notation total function" which are
     extracted as aliases

4. CLDR Annotations
   - Source: Unicode Common Locale Data Repository (CLDR)
   - Content: Common names and descriptions for characters in various languages
   - URL: https://raw.githubusercontent.com/unicode-org/cldr/main/common/annotations/en.xml
   - Format: XML file with entries like <annotation cp="→">arrow | right | right-pointing</annotation>

DATA PROCESSING
--------------

The script processes these sources in the following way:

1. Download the source files from their respective URLs
   - Files can be cached locally to avoid repeated downloads
   - Caching helps with rate limiting and offline development

2. Parse each source file to extract relevant information:
   - UnicodeData.txt: Extract code points, character names, and categories
   - NameAliases.txt: Extract formal aliases
   - NamesList.txt: Extract informative aliases from lines starting with "="
   - CLDR Annotations: Extract common names and descriptions

3. Merge the aliases from all sources:
   - Formal aliases from NameAliases.txt
   - Informative aliases from NamesList.txt
   - Common names from CLDR Annotations

4. Generate output files in multiple formats:
   - CSV: For easy viewing and processing
   - JSON: For web applications
   - Lua: For direct use in Neovim plugins
   - Text: For grep-friendly searching

EXAMPLE
-------

For the RIGHTWARDS ARROW character (U+2192, →):

- Official name: "RIGHTWARDS ARROW"
- Category: "Sm" (Symbol, Math)
- Aliases:
  - From NamesList.txt: "z notation total function"
  - From CLDR: "arrow", "right", "right-pointing"

The combined data in Lua format looks like:

  {
    code_point = "U+2192",
    character = "→",
    name = "RIGHTWARDS ARROW",
    category = "Sm",
    aliases = {
      "z notation total function",
      "arrow",
      "right",
      "right-pointing",
    },
  }

USAGE
-----

Basic usage:
  poetry run python -m unifill_datafetch generate --format all

Options:
  --format FORMAT    Output format: csv, json, lua, txt, or all (default: csv)
  --output-dir DIR   Output directory (default: current directory)
  --use-cache        Use cached files if available
  --cache-dir DIR    Directory to store cached files (default: ./cache)

You can also use the CLI to get information about the data formats:
  poetry run python -m unifill_datafetch info

The script will generate the following files:
  - unicode_data.csv: CSV format
  - unicode_data.json: JSON format
  - unicode_data.lua: Lua module
  - unicode_data.txt: Text format optimized for grep

EXTENDING THE DATASET
--------------------

The dataset can be extended with additional sources:

1. Additional CLDR languages:
   - Download language-specific annotation files (e.g., fr.xml for French)
   - Parse them similar to the English annotations
   - Store with language tags

2. Other potential sources:
   - HTML/XML entity references (e.g., &rarr; for the right arrow →)
   - LaTeX commands (e.g., \rightarrow for the right arrow →)
   - Programming language escape sequences
   - Emoji database descriptions for emoji characters

To add a new source, implement a parser function similar to the existing ones
and merge the results into the aliases_info dictionary.
