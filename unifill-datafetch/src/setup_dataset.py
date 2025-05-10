"""
This module downloads and processes Unicode character data to create a dataset in various formats.

The script performs the following operations:
1. Downloads the latest Unicode Character Database (UCD) files to system temp directory:
   - UnicodeData.txt: Contains primary character information
   - NameAliases.txt: Contains alternative names for characters

2. Processes these files to extract:
   - Character code points
   - Actual characters
   - Official character names
   - General categories
   - Name aliases

3. Generates output in one of these formats:
   - CSV: unicode_characters_table.csv
   - JSON: unicode_characters_table.json
   - Lua: unicode_data.lua (as a Lua module)

Output format can be specified with --format option (default: csv)
"""

import requests
import csv
import json
import argparse
import os
import tempfile
from collections import defaultdict
from pathlib import Path

# --- Configuration ---
UCD_LATEST_URL = "https://www.unicode.org/Public/UCD/latest/ucd/"
UNICODE_DATA_FILE_URL = UCD_LATEST_URL + "UnicodeData.txt"
NAME_ALIASES_FILE_URL = UCD_LATEST_URL + "NameAliases.txt"

# Output file names for different formats
OUTPUT_FILES = {
    'csv': "unicode_characters_table.csv",
    'json': "unicode_characters_table.json",
    'lua': "unicode_data.lua"
}

# --- Helper Functions ---

def download_file(url):
    """Downloads a file from a URL to a temporary file and returns its path."""
    try:
        # Create a temporary file that will be automatically cleaned up
        temp_file = tempfile.NamedTemporaryFile(delete=False)
        
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        with temp_file as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return temp_file.name
    except requests.exceptions.RequestException as e:
        print(f"Error downloading {url}: {e}")
        return None

def parse_unicode_data(filename):
    """
    Parses UnicodeData.txt.
    Returns a dictionary: {code_point: {'name': name, 'category': category, 'char_obj': char}}
    Skips character range definitions.
    """
    data = {}
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                fields = line.strip().split(';')
                if len(fields) >= 3:
                    code_point_hex = fields[0]
                    name = fields[1]
                    category = fields[2]

                    if name.startswith('<') and name.endswith(', First>'):
                        continue
                    if name.startswith('<') and name.endswith(', Last>'):
                        continue

                    try:
                        char_obj = chr(int(code_point_hex, 16))
                        data[code_point_hex] = {
                            'name': name,
                            'category': category,
                            'char_obj': char_obj
                        }
                    except ValueError:
                        print(f"Skipping invalid code point: {code_point_hex} - {name}")
                        continue
        return data
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return None

def parse_name_aliases(filename):
    """
    Parses NameAliases.txt.
    Returns a defaultdict: {code_point: [list_of_aliases]}
    """
    aliases_data = defaultdict(list)
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                fields = line.split(';')
                if len(fields) >= 2:
                    code_point_hex = fields[0]
                    alias = fields[1]
                    aliases_data[code_point_hex].append(alias)
        return aliases_data
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return None

def write_csv_output(unicode_data, aliases_data, output_filename):
    """Writes the data in CSV format."""
    if not unicode_data:
        print("No Unicode data to write. Aborting CSV creation.")
        return

    max_aliases = 0
    if aliases_data:
        for cp in unicode_data.keys():
            if cp in aliases_data:
                max_aliases = max(max_aliases, len(aliases_data[cp]))

    headers = ['code_point', 'character', 'name', 'category']
    for i in range(1, max_aliases + 1):
        headers.append(f'alias_{i}')

    try:
        with open(output_filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(headers)

            for code_point_hex, data in unicode_data.items():
                current_aliases = aliases_data.get(code_point_hex, [])
                row = [
                    f"U+{code_point_hex}",
                    data['char_obj'],
                    data['name'],
                    data['category']
                ]
                for i in range(max_aliases):
                    row.append(current_aliases[i] if i < len(current_aliases) else '')
                writer.writerow(row)

    except Exception as e:
        print(f"Error writing CSV file: {e}")

def write_json_output(unicode_data, aliases_data, output_filename):
    """Writes the data in JSON format."""
    if not unicode_data:
        print("No Unicode data to write. Aborting JSON creation.")
        return

    json_data = []
    for code_point_hex, data in unicode_data.items():
        entry = {
            'code_point': f"U+{code_point_hex}",
            'character': data['char_obj'],
            'name': data['name'],
            'category': data['category'],
            'aliases': aliases_data.get(code_point_hex, [])
        }
        json_data.append(entry)

    try:
        with open(output_filename, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"Error writing JSON file: {e}")

def write_lua_output(unicode_data, aliases_data, output_filename):
    """Writes the data as a Lua module."""
    if not unicode_data:
        print("No Unicode data to write. Aborting Lua module creation.")
        return

    try:
        with open(output_filename, 'w', encoding='utf-8') as f:
            f.write("-- Auto-generated unicode data module\n")
            f.write("return {\n")
            
            for code_point_hex, data in unicode_data.items():
                aliases = aliases_data.get(code_point_hex, [])
                # Handle special characters for Lua
                char = data['char_obj']
                if char == '\n':
                    char = '\\n'
                elif char == '\r':
                    char = '\\r'
                elif char == '\t':
                    char = '\\t'
                elif char == '"':
                    char = '\\"'
                elif char == '\\':
                    char = '\\\\'
                elif ord(char) < 32:  # Other control characters
                    char = f'\\{ord(char):03d}'
                name = data['name'].replace('"', '\\"')
                
                f.write("  {\n")
                f.write(f'    code_point = "U+{code_point_hex}",\n')
                f.write(f'    character = "{char}",\n')
                f.write(f'    name = "{name}",\n')
                f.write(f'    category = "{data["category"]}",\n')
                
                # Write aliases as a Lua table
                if aliases:
                    f.write('    aliases = {\n')
                    for alias in aliases:
                        escaped_alias = alias.replace('"', '\\"')
                        f.write(f'      "{escaped_alias}",\n')
                    f.write('    },\n')
                else:
                    f.write('    aliases = {},\n')
                
                f.write("  },\n")
            
            f.write("}\n")
    except Exception as e:
        print(f"Error writing Lua module: {e}")

# --- Main Execution ---
def main():
    parser = argparse.ArgumentParser(description='Process Unicode data into various formats')
    parser.add_argument('--format', choices=['csv', 'json', 'lua'], default='csv',
                      help='Output format (default: csv)')
    args = parser.parse_args()

    # Download files to temporary location
    unicode_data_file = download_file(UNICODE_DATA_FILE_URL)
    name_aliases_file = download_file(NAME_ALIASES_FILE_URL)

    if not (unicode_data_file and name_aliases_file):
        print("One or more files failed to download. Aborting.")
        return

    try:
        # Parse the downloaded files
        unicode_char_info = parse_unicode_data(unicode_data_file)
        aliases_info = parse_name_aliases(name_aliases_file)

        if unicode_char_info is None or aliases_info is None:
            print("Failed to parse one or more data files. Aborting.")
            return

        # Write output in the specified format
        output_filename = OUTPUT_FILES[args.format]
        if args.format == 'csv':
            write_csv_output(unicode_char_info, aliases_info, output_filename)
        elif args.format == 'json':
            write_json_output(unicode_char_info, aliases_info, output_filename)
        else:  # lua
            write_lua_output(unicode_char_info, aliases_info, output_filename)

        print(f"Data written to {output_filename}")

    finally:
        # Clean up temporary files
        if unicode_data_file:
            os.unlink(unicode_data_file)
        if name_aliases_file:
            os.unlink(name_aliases_file)

if __name__ == "__main__":
    main()