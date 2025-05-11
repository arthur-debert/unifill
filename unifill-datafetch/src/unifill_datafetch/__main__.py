"""
Command-line interface for the unifill-datafetch package.

This module provides a CLI interface using Click to download and process
Unicode character data for the Unifill Neovim plugin.
"""

import os
import click
from .core import process_unicode_data, OUTPUT_FILES

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
    default="./cache",
    help="Directory to store cached files (default: ./cache)",
)
def generate(format, output_dir, use_cache, cache_dir):
    """
    Generate Unicode character dataset in the specified format.
    
    Downloads Unicode data files, processes them, and generates output
    in the specified format. The output can be in CSV, JSON, Lua, or
    text format, or all formats at once.
    """
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Process the data
    success, output_files = process_unicode_data(
        format_type=format,
        output_dir=output_dir,
        use_cache=use_cache,
        cache_dir=cache_dir
    )
    
    if success:
        click.echo(click.style("✓ Unicode data processing completed successfully!", fg="green"))
        click.echo("Generated files:")
        for file_path in output_files:
            click.echo(f"  - {file_path}")
    else:
        click.echo(click.style("✗ Unicode data processing failed.", fg="red"))
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