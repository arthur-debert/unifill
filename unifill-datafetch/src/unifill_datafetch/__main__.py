"""
Command-line interface for the unifill-datafetch package.
"""

import os
import click
from typing import Tuple, List

from .types import FetchOptions, ExportOptions
from .fetcher import fetch_all_data_files
from .processor import process_data_files
from .exporter import export_data, save_source_files
from .config import DEFAULT_CACHE_DIR


def process_unicode_data(
    fetch_options: FetchOptions,
    export_options: ExportOptions
) -> Tuple[bool, List[str]]:
    """
    Process Unicode data and generate output files.
    
    Args:
        fetch_options: Options for fetching Unicode data files
        export_options: Options for exporting Unicode data
        
    Returns:
        Tuple of (success, output_files) where success is a boolean indicating
        if the operation was successful, and output_files is a list of generated file paths.
    """
    # Fetch the data files
    file_paths = fetch_all_data_files(fetch_options)
    if not file_paths:
        print("Failed to fetch data files")
        return False, []
    
    # Process the data files
    unicode_data, aliases_data = process_data_files(file_paths)
    if not unicode_data or not aliases_data:
        print("Failed to process data files")
        return False, []
    
    # Export the data
    output_files = export_data(unicode_data, aliases_data, export_options)
    
    # Save the source files
    save_source_files(file_paths, export_options.output_dir)
    
    return bool(output_files), output_files


@click.group()
def cli():
    """
    Unifill-datafetch: Download and process Unicode character data.
    
    This tool downloads Unicode character data from various sources,
    processes it, and generates output in different formats for use
    with the Unifill Neovim plugin.
    """
    pass


@cli.command()
@click.option(
    "--format",
    type=click.Choice(["csv", "json", "lua", "txt", "all"]),
    default="csv",
    help="Output format (default: csv)",
)
@click.option(
    "--output-dir",
    type=click.Path(exists=False, file_okay=False, dir_okay=True),
    default=".",
    help="Output directory (default: current directory)",
)
@click.option(
    "--use-cache/--no-cache",
    default=False,
    help="Use cached files if available",
)
@click.option(
    "--cache-dir",
    type=click.Path(exists=False, file_okay=False, dir_okay=True),
    default=DEFAULT_CACHE_DIR,
    help=f"Directory to store cached files (default: {DEFAULT_CACHE_DIR})",
)
@click.option(
    "--exit-on-error",
    is_flag=True,
    default=False,
    help="Exit with code 1 on error",
)
def generate(format, output_dir, use_cache, cache_dir, exit_on_error):
    """
    Generate Unicode character dataset in the specified format.
    
    Downloads Unicode data files, processes them, and generates output
    in the specified format. The output can be in CSV, JSON, Lua, or
    text format, or all formats at once.
    """
    # Create options objects
    fetch_options = FetchOptions(use_cache=use_cache, cache_dir=cache_dir)
    export_options = ExportOptions(format_type=format, output_dir=output_dir)
    
    # Process the data
    success, output_files = process_unicode_data(fetch_options, export_options)
    
    if success:
        click.echo(click.style("✓ Unicode data processing completed successfully!", fg="green"))
        click.echo("Generated files:")
        for file_path in output_files:
            click.echo(f"  - {file_path}")
        return 0
    else:
        click.echo(click.style("✗ Unicode data processing failed.", fg="red"))
        if exit_on_error:
            return 1
        return 0


@cli.command()
def info():
    """
    Display information about the Unicode data formats.
    
    Shows details about the available output formats and their uses.
    """
    click.echo("Unifill-datafetch: Unicode Data Format Information")
    click.echo("==============================================")
    click.echo("")
    click.echo("Available output formats:")
    click.echo("")
    click.echo("1. CSV (unicode_data.csv)")
    click.echo("   - Tabular format with columns for code point, character, name, category, and aliases")
    click.echo("   - Good for viewing in spreadsheet applications")
    click.echo("")
    click.echo("2. JSON (unicode_data.json)")
    click.echo("   - Structured format with objects for each character")
    click.echo("   - Useful for web applications or further processing")
    click.echo("")
    click.echo("3. Lua (unicode_data.lua)")
    click.echo("   - Lua module format for direct use in Neovim plugins")
    click.echo("   - Default format used by the Unifill plugin")
    click.echo("")
    click.echo("4. Text (unicode_data.txt)")
    click.echo("   - Pipe-separated format optimized for grep-based searching")
    click.echo("   - Used by the grep backend in Unifill")
    click.echo("")
    click.echo("Use the 'generate' command with the --format option to create these files.")


def main():
    """Entry point for the CLI."""
    return cli()


if __name__ == "__main__":
    main()