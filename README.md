# xgrep - Advanced Language-Specific Grep Tool

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A collection of specialized grep tools that search within specific language files by extension and shebang detection. Utilizes ripgrep for performance when available, with graceful fallback to standard grep.

## Features

- **Language-specific search**: Target files in specific languages with customized tools
  - `bashgrep`: Search only in Bash script files
  - `phpgrep`: Search only in PHP files
  - `pygrep`: Search only in Python files
  - `xgrep`: Search across all supported language files
- **Auto-detection**: Finds files by extension or shebang line
- **Performance**: Uses ripgrep when available for significantly faster searching
- **Graceful degradation**: Falls back to grep+find when ripgrep is not installed
- **Configurable exclusions**: Easily exclude directories from search
- **Simple interface**: Familiar grep-like interface with added features

## Installation

Clone the repository:

```bash
git clone https://github.com/Open-Technology-Foundation/xgrep.git
cd xgrep
```

Create symlinks to the main script:

```bash
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/xgrep
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/bashgrep
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/phpgrep
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/pygrep
```

Or use it directly from the cloned directory.

## Performance Recommendation

For best performance, install ripgrep:

- Debian/Ubuntu: `sudo apt install ripgrep`
- Fedora: `sudo dnf install ripgrep`
- macOS: `brew install ripgrep`
- See [ripgrep installation](https://github.com/BurntSushi/ripgrep#installation) for all platforms

## Usage

Basic usage pattern:

```bash
xgrep [options] [ripgrep_options] pattern [directory]
```

Language-specific examples:

```bash
# Search for "function" in all Bash scripts
bashgrep "function" ~/scripts

# Find all PHP classes in a web project
phpgrep "class " ~/webproject

# Look for boto3 imports in Python code
pygrep "import boto3" ~/python-projects

# Search across all supported languages
xgrep "TODO:" ~/development
```

## Options

- `-d, --maxdepth N`: Set search depth (default: unlimited)
- `-X, --exclude-dir DIR[,...]`: Exclude directories from search
- `-D, --debug`: Show debug information
- `-V, --version`: Display version
- `--help`: Display help information
- `--`, `--rg`: Pass all following options directly to ripgrep

You can also use most standard ripgrep/grep options.

## Environment Variables

- `XGREP_EXCLUDE_DIRS`: Override default excluded directories
- `RG_CMD=grep_fallback`: Force use of grep instead of ripgrep

## File Detection

The tools detect files by:
1. File extensions: `.sh`, `.bash`, `.php`, `.phtml`, `.py`, `.pyw`
2. Shebang detection: Files without extensions that contain appropriate shebangs

## Author

Gary Dean - Open Technology Foundation

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.