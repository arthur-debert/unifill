"""
Configuration constants and settings for the unifill-datafetch package.
"""

# URLs for data sources
UCD_LATEST_URL = "https://www.unicode.org/Public/UCD/latest/ucd/"
UNICODE_DATA_FILE_URL = UCD_LATEST_URL + "UnicodeData.txt"
NAME_ALIASES_FILE_URL = UCD_LATEST_URL + "NameAliases.txt"
NAMES_LIST_FILE_URL = UCD_LATEST_URL + "NamesList.txt"
CLDR_ANNOTATIONS_URL = "https://raw.githubusercontent.com/unicode-org/cldr/main/common/annotations/en.xml"

# Output file names for different formats
OUTPUT_FILES = {
    'csv': "unicode_data.csv",
    'json': "unicode_data.json",
    'lua': "unicode_data.lua",
    'txt': "unicode_data.txt"
}

# Default cache directory
DEFAULT_CACHE_DIR = "./cache"

# User agent for HTTP requests
USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'