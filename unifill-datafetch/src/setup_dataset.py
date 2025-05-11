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
import xml.etree.ElementTree as ET
from collections import defaultdict

# --- Configuration ---
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

# --- Helper Functions ---

def download_file(url, use_cache=False, cache_dir=None):
    """
    Downloads a file from a URL to a temporary file and returns its path.
    If use_cache is True, it will check for a cached version of the file first.
    """
    # Extract the filename from the URL
    filename = os.path.basename(url)
    
    # If cache is enabled, check if the file exists in the cache directory
    if use_cache and cache_dir:
        cache_path = os.path.join(cache_dir, filename)
        if os.path.exists(cache_path):
            print(f"Using cached file: {cache_path}")
            return cache_path
    
    try:
        # Create a temporary file that will be automatically cleaned up
        temp_file = tempfile.NamedTemporaryFile(delete=False)
        
        # Add a user agent to avoid rate limiting
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(url, stream=True, headers=headers)
        response.raise_for_status()
        
        with temp_file as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        # If cache is enabled, save the file to the cache directory
        if use_cache and cache_dir:
            os.makedirs(cache_dir, exist_ok=True)
            cache_path = os.path.join(cache_dir, filename)
            with open(temp_file.name, 'rb') as src, open(cache_path, 'wb') as dst:
                dst.write(src.read())
            print(f"Cached file to: {cache_path}")
            return cache_path
        
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

def parse_names_list(filename):
    """
    Parses NamesList.txt to extract informative aliases.
    Returns a defaultdict: {code_point_hex: [list_of_informative_aliases]}
    """
    informative_aliases = defaultdict(list)
    current_code_point = None
    
    print(f"Starting to parse {filename}")
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            line_number = 0
            for line in f:
                line_number += 1
                original_line = line
                line = line.strip()
                
                # Skip comments, headers, and empty lines
                if not line or line.startswith('@') or line.startswith(';'):
                    continue
                
                # Check if this is a new character definition
                if not original_line.startswith('\t'):
                    parts = line.split('\t', 1)
                    if len(parts) == 2:
                        try:
                            # Store the code point as a hex string
                            current_code_point = parts[0].strip()
                            # Debug output for specific code points
                            if current_code_point == "2192":
                                print(f"Line {line_number}: Found RIGHTWARDS ARROW: {current_code_point}")
                        except ValueError:
                            current_code_point = None
                    else:
                        current_code_point = None
                # Check if this is an informative alias (starts with "= ")
                elif current_code_point and '=' in line and line.lstrip().startswith('='):
                    # Extract the alias (remove the "= " prefix)
                    alias = line.lstrip()[1:].strip()
                    # Convert code point to uppercase hex format to match unicode_char_info keys
                    code_point_hex = current_code_point.upper()
                    informative_aliases[code_point_hex].append(alias)
                    # Debug output for specific code points
                    if current_code_point == "2192":
                        print(f"Line {line_number}: Added alias for RIGHTWARDS ARROW: '{alias}'")
                # Also include cross-references as aliases (lines starting with "* ")
                elif current_code_point and '*' in line and line.lstrip().startswith('*'):
                    # Extract the descriptive note (remove the "* " prefix)
                    note = line.lstrip()[1:].strip()
                    # Only include if it's not too long and doesn't contain references to other characters
                    if len(note) < 50 and not "(" in note and not ")" in note:
                        code_point_hex = current_code_point.upper()
                        informative_aliases[code_point_hex].append(note)
                        # Debug output for specific code points
                        if current_code_point == "2192":
                            print(f"Line {line_number}: Added note for RIGHTWARDS ARROW: '{note}'")
                
                # Debug output for any line after RIGHTWARDS ARROW
                if current_code_point == "2192" and original_line.startswith('\t'):
                    print(f"Line {line_number}: Processing line for RIGHTWARDS ARROW: '{line}'")
        
        # Debug output for the final result
        if "2192" in informative_aliases:
            print(f"Final aliases for RIGHTWARDS ARROW: {informative_aliases['2192']}")
        else:
            print(f"No aliases found for RIGHTWARDS ARROW")
        
        return informative_aliases
    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return None
    except Exception as e:
        print(f"An error occurred while parsing {filename}: {e}")
        return None

def parse_cldr_annotations(filename):
    """
    Parses CLDR annotations XML file to extract common names and descriptions for Unicode characters.
    Returns a defaultdict: {code_point_hex: [list_of_annotations]}
    """
    cldr_annotations = defaultdict(list)
    
    try:
        tree = ET.parse(filename)
        root = tree.getroot()
        
        # Find all annotation elements
        for annotation in root.findall(".//annotation"):
            # Skip text-to-speech annotations (type="tts")
            if 'type' in annotation.attrib:
                continue
                
            # Get the character code point
            if 'cp' in annotation.attrib:
                char = annotation.attrib['cp']
                # Convert character to code point
                if len(char) == 1:
                    code_point_hex = format(ord(char), 'X')
                else:
                    # Handle multi-character code points
                    code_point_hex = format(ord(char[0]), 'X')
                    
                # Get the annotations (pipe-separated list)
                if annotation.text:
                    # Split by pipe and strip whitespace
                    aliases = [alias.strip() for alias in annotation.text.split('|')]
                    cldr_annotations[code_point_hex].extend(aliases)
                    
                    # Debug output for specific code points
                    if code_point_hex == "2192":
                        print(f"Added CLDR annotations for RIGHTWARDS ARROW: {aliases}")
        
        return cldr_annotations
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

def write_txt_output(unicode_data, aliases_data, output_filename):
    """Writes the data in a grep-friendly text format optimized for fast searching."""
    if not unicode_data:
        print("No Unicode data to write. Aborting text file creation.")
        return

    try:
        with open(output_filename, 'w', encoding='utf-8') as f:
            for code_point_hex, data in unicode_data.items():
                # Format: character|name|code_point|category|alias1|alias2|...
                # Optimized for grep with searchable fields first
                
                # Prepare the name and aliases for better searchability
                name = data['name']
                
                # Create the base parts of the line
                line_parts = [
                    data['char_obj'],
                    name,
                    f"U+{code_point_hex}",
                    data['category']
                ]
                
                # Add aliases if they exist
                if code_point_hex in aliases_data:
                    line_parts.extend(aliases_data[code_point_hex])
                
                # Join with pipe separator
                f.write('|'.join(line_parts) + '\n')
    except Exception as e:
        print(f"Error writing text file: {e}")

# --- Main Execution ---
def main():
    parser = argparse.ArgumentParser(description='Process Unicode data into various formats')
    parser.add_argument('--format', choices=['csv', 'json', 'lua', 'txt', 'all'], default='csv',
                      help='Output format (default: csv)')
    parser.add_argument('--output-dir', default='.',
                      help='Output directory (default: current directory)')
    parser.add_argument('--use-cache', action='store_true',
                      help='Use cached files if available')
    parser.add_argument('--cache-dir', default='./cache',
                      help='Directory to store cached files (default: ./cache)')
    args = parser.parse_args()

    # Download files to temporary location
    unicode_data_file = download_file(UNICODE_DATA_FILE_URL, args.use_cache, args.cache_dir)
    name_aliases_file = download_file(NAME_ALIASES_FILE_URL, args.use_cache, args.cache_dir)
    names_list_file = download_file(NAMES_LIST_FILE_URL, args.use_cache, args.cache_dir)
    cldr_annotations_file = download_file(CLDR_ANNOTATIONS_URL, args.use_cache, args.cache_dir)

    if not (unicode_data_file and name_aliases_file and names_list_file):
        print("One or more required files failed to download. Aborting.")
        return

    try:
        # Parse the downloaded files
        unicode_char_info = parse_unicode_data(unicode_data_file)
        formal_aliases_info = parse_name_aliases(name_aliases_file)
        informative_aliases_info = parse_names_list(names_list_file)
        
        # CLDR annotations are optional, so we don't abort if they're missing
        cldr_annotations_info = None
        if cldr_annotations_file:
            cldr_annotations_info = parse_cldr_annotations(cldr_annotations_file)
            if cldr_annotations_info is None:
                print("Warning: Failed to parse CLDR annotations file. Continuing without CLDR annotations.")

        if unicode_char_info is None or formal_aliases_info is None or informative_aliases_info is None:
            print("Failed to parse one or more required data files. Aborting.")
            return
            
        # Merge formal and informative aliases
        aliases_info = defaultdict(list)
        for code_point, aliases in formal_aliases_info.items():
            aliases_info[code_point].extend(aliases)
            if code_point == "2192":
                print(f"Added formal aliases for RIGHTWARDS ARROW: {aliases}")
        
        for code_point, aliases in informative_aliases_info.items():
            # Convert code point format to match the one used in unicode_char_info
            code_point_hex = code_point.upper()
            aliases_info[code_point_hex].extend(aliases)
            if code_point == "2192":
                print(f"Added informative aliases for RIGHTWARDS ARROW: {aliases}")
        
        # Add CLDR annotations if available
        if cldr_annotations_info:
            for code_point, annotations in cldr_annotations_info.items():
                aliases_info[code_point].extend(annotations)
                if code_point == "2192":
                    print(f"Added CLDR annotations for RIGHTWARDS ARROW: {annotations}")
        
        # Debug output for the final result
        if "2192" in aliases_info:
            print(f"Final aliases for RIGHTWARDS ARROW: {aliases_info['2192']}")

        # Write output in the specified format
        if args.format == 'all':
            formats = ['csv', 'lua', 'txt']
        else:
            formats = [args.format]
            
        for fmt in formats:
            output_filename = os.path.join(args.output_dir, OUTPUT_FILES[fmt])
            if fmt == 'csv':
                write_csv_output(unicode_char_info, aliases_info, output_filename)
            elif fmt == 'json':
                write_json_output(unicode_char_info, aliases_info, output_filename)
            elif fmt == 'txt':
                write_txt_output(unicode_char_info, aliases_info, output_filename)
            else:  # lua
                write_lua_output(unicode_char_info, aliases_info, output_filename)
            
            print(f"Data written to {output_filename}")

    finally:
        # Copy the downloaded files to the current directory instead of deleting them
        if unicode_data_file:
            import shutil
            shutil.copy(unicode_data_file, "UnicodeData.txt")
            print(f"Saved Unicode data file to UnicodeData.txt")
        if name_aliases_file:
            import shutil
            shutil.copy(name_aliases_file, "NameAliases.txt")
            print(f"Saved name aliases file to NameAliases.txt")
        if names_list_file:
            import shutil
            shutil.copy(names_list_file, "NamesList.txt")
            print(f"Saved names list file to NamesList.txt")

if __name__ == "__main__":
    main()