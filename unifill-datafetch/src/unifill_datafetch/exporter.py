"""
Module for exporting Unicode data to various formats.
"""

import os
import csv
import json
from typing import Dict, List, Optional

from .types import UnicodeCharInfo, ExportOptions
from .config import OUTPUT_FILES


def write_csv_output(
    unicode_data: Dict[str, UnicodeCharInfo],
    aliases_data: Dict[str, List[str]],
    output_filename: str
) -> bool:
    """
    Write Unicode data to CSV format.
    
    Args:
        unicode_data: Dictionary mapping code points to character info
        aliases_data: Dictionary mapping code points to lists of aliases
        output_filename: Path to write the output file
        
    Returns:
        True if successful, False otherwise
    """
    if not unicode_data:
        print("No Unicode data to write. Aborting CSV creation.")
        return False

    # Determine the maximum number of aliases for any character
    max_aliases = 0
    if aliases_data:
        for cp in unicode_data.keys():
            if cp in aliases_data:
                max_aliases = max(max_aliases, len(aliases_data[cp]))

    # Create the CSV headers
    headers = ['code_point', 'character', 'name', 'category']
    for i in range(1, max_aliases + 1):
        headers.append(f'alias_{i}')

    try:
        with open(output_filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(headers)

            for code_point_hex, char_info in unicode_data.items():
                current_aliases = aliases_data.get(code_point_hex, [])
                row = [
                    f"U+{code_point_hex}",
                    char_info.char_obj,
                    char_info.name,
                    char_info.category
                ]
                for i in range(max_aliases):
                    row.append(current_aliases[i] if i < len(current_aliases) else '')
                writer.writerow(row)
        
        return True
    except Exception as e:
        print(f"Error writing CSV file: {e}")
        return False


def write_json_output(
    unicode_data: Dict[str, UnicodeCharInfo],
    aliases_data: Dict[str, List[str]],
    output_filename: str
) -> bool:
    """
    Write Unicode data to JSON format.
    
    Args:
        unicode_data: Dictionary mapping code points to character info
        aliases_data: Dictionary mapping code points to lists of aliases
        output_filename: Path to write the output file
        
    Returns:
        True if successful, False otherwise
    """
    if not unicode_data:
        print("No Unicode data to write. Aborting JSON creation.")
        return False

    json_data = []
    for code_point_hex, char_info in unicode_data.items():
        entry = {
            'code_point': f"U+{code_point_hex}",
            'character': char_info.char_obj,
            'name': char_info.name,
            'category': char_info.category,
            'aliases': aliases_data.get(code_point_hex, [])
        }
        json_data.append(entry)

    try:
        with open(output_filename, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"Error writing JSON file: {e}")
        return False


def write_lua_output(
    unicode_data: Dict[str, UnicodeCharInfo],
    aliases_data: Dict[str, List[str]],
    output_filename: str
) -> bool:
    """
    Write Unicode data to Lua module format.
    
    Args:
        unicode_data: Dictionary mapping code points to character info
        aliases_data: Dictionary mapping code points to lists of aliases
        output_filename: Path to write the output file
        
    Returns:
        True if successful, False otherwise
    """
    if not unicode_data:
        print("No Unicode data to write. Aborting Lua module creation.")
        return False

    try:
        with open(output_filename, 'w', encoding='utf-8') as f:
            f.write("-- Auto-generated unicode data module\n")
            f.write("return {\n")
            
            for code_point_hex, char_info in unicode_data.items():
                aliases = aliases_data.get(code_point_hex, [])
                # Handle special characters for Lua
                char = char_info.char_obj
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
                name = char_info.name.replace('"', '\\"')
                
                f.write("  {\n")
                f.write(f'    code_point = "U+{code_point_hex}",\n')
                f.write(f'    character = "{char}",\n')
                f.write(f'    name = "{name}",\n')
                f.write(f'    category = "{char_info.category}",\n')
                
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
        return True
    except Exception as e:
        print(f"Error writing Lua module: {e}")
        return False


def write_txt_output(
    unicode_data: Dict[str, UnicodeCharInfo],
    aliases_data: Dict[str, List[str]],
    output_filename: str
) -> bool:
    """
    Write Unicode data to text format optimized for grep.
    
    Args:
        unicode_data: Dictionary mapping code points to character info
        aliases_data: Dictionary mapping code points to lists of aliases
        output_filename: Path to write the output file
        
    Returns:
        True if successful, False otherwise
    """
    if not unicode_data:
        print("No Unicode data to write. Aborting text file creation.")
        return False

    try:
        with open(output_filename, 'w', encoding='utf-8') as f:
            for code_point_hex, char_info in unicode_data.items():
                # Format: character|name|code_point|category|alias1|alias2|...
                # Optimized for grep with searchable fields first
                
                # Create the base parts of the line
                line_parts = [
                    char_info.char_obj,
                    char_info.name,
                    f"U+{code_point_hex}",
                    char_info.category
                ]
                
                # Add aliases if they exist
                if code_point_hex in aliases_data:
                    line_parts.extend(aliases_data[code_point_hex])
                
                # Join with pipe separator
                f.write('|'.join(line_parts) + '\n')
        return True
    except Exception as e:
        print(f"Error writing text file: {e}")
        return False


def export_data(
    unicode_data: Dict[str, UnicodeCharInfo],
    aliases_data: Dict[str, List[str]],
    options: ExportOptions
) -> List[str]:
    """
    Export Unicode data to the specified format.
    
    Args:
        unicode_data: Dictionary mapping code points to character info
        aliases_data: Dictionary mapping code points to lists of aliases
        options: Export options including format type and output directory
        
    Returns:
        List of paths to generated files
    """
    output_files = []
    
    # Determine which formats to generate
    formats = []
    if options.format_type == 'all':
        formats = ['csv', 'json', 'lua', 'txt']
    else:
        formats = [options.format_type]
    
    # Create the output directory if it doesn't exist
    os.makedirs(options.output_dir, exist_ok=True)
    
    # Generate each format
    for fmt in formats:
        output_filename = os.path.join(options.output_dir, OUTPUT_FILES[fmt])
        success = False
        
        if fmt == 'csv':
            success = write_csv_output(unicode_data, aliases_data, output_filename)
        elif fmt == 'json':
            success = write_json_output(unicode_data, aliases_data, output_filename)
        elif fmt == 'txt':
            success = write_txt_output(unicode_data, aliases_data, output_filename)
        else:  # lua
            success = write_lua_output(unicode_data, aliases_data, output_filename)
        
        if success:
            output_files.append(output_filename)
            print(f"Data written to {output_filename}")
    
    return output_files


def save_source_files(file_paths: Dict[str, str], output_dir: str) -> None:
    """
    Save the source files to the output directory.
    
    Args:
        file_paths: Dictionary mapping file types to file paths
        output_dir: Directory to save the files
    """
    import shutil
    
    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Save UnicodeData.txt
    if 'unicode_data' in file_paths:
        shutil.copy(file_paths['unicode_data'], os.path.join(output_dir, "UnicodeData.txt"))
        print(f"Saved Unicode data file to {os.path.join(output_dir, 'UnicodeData.txt')}")
    
    # Save NameAliases.txt
    if 'name_aliases' in file_paths:
        shutil.copy(file_paths['name_aliases'], os.path.join(output_dir, "NameAliases.txt"))
        print(f"Saved name aliases file to {os.path.join(output_dir, 'NameAliases.txt')}")
    
    # Save NamesList.txt
    if 'names_list' in file_paths:
        shutil.copy(file_paths['names_list'], os.path.join(output_dir, "NamesList.txt"))
        print(f"Saved names list file to {os.path.join(output_dir, 'NamesList.txt')}")