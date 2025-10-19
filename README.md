# xgrep - Advanced Language-Specific Grep Tool

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A powerful collection of specialized grep tools that search within specific programming language files using comprehensive file detection by extension, shebang analysis, and MIME type inspection. Features a hybrid approach that combines ripgrep's exceptional search performance with robust file type detection.

## Key Features

- **Language-Specific Search**: Targeted searching in specific programming languages
  - `bashgrep`: Search only in Bash script files (`.sh`, `.bash`, shebangs)
  - `phpgrep`: Search only in PHP files (`.php`, `.phtml`, shebangs)  
  - `pygrep`: Search only in Python files (`.py`, `.pyw`, shebangs)
  - `xgrep`: Search across all supported languages simultaneously

- **Comprehensive File Detection**: Advanced file type detection using:
  - **File extensions**: Standard extension-based detection
  - **Shebang analysis**: Detects files by interpreter directives (`#!/usr/bin/env python3`)
  - **MIME type inspection**: Uses `file` command for additional validation
  - **Binary detection**: Automatically excludes binary files

- **Hybrid Performance**: Best of both worlds approach
  - **Phase 1**: Comprehensive file discovery using advanced detection
  - **Phase 2**: High-speed search using ripgrep on discovered files
  - **Fallback**: Graceful degradation to find+grep when ripgrep unavailable

- **Smart Exclusions**: Automatically excludes common directories:
  - Build artifacts: `.venv`, `node_modules`, `build/`
  - Version control: `.git/`, `.svn/`
  - Temporary files: `tmp/`, `.tmp/`, `temp/`
  - Cache directories: `.cache/`, `__pycache__/`

- **Terminal Integration**: Automatic color output and formatting
- **Flexible Configuration**: Environment variables and command-line customization

## Installation

### Quick Install

```bash
git clone https://github.com/Open-Technology-Foundation/xgrep.git
cd xgrep
```

### System-Wide Installation

```bash
# Create symlinks for all tools
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/xgrep
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/bashgrep
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/phpgrep
sudo ln -sf "$(pwd)/xgrep" /usr/local/bin/pygrep
```

### Local Installation

```bash
# Add to your PATH or create local symlinks
mkdir -p ~/.local/bin
ln -sf "$(pwd)/xgrep" ~/.local/bin/xgrep
ln -sf "$(pwd)/xgrep" ~/.local/bin/bashgrep
ln -sf "$(pwd)/xgrep" ~/.local/bin/phpgrep
ln -sf "$(pwd)/xgrep" ~/.local/bin/pygrep
```

**Note**: When run as `xgrep`, the tool automatically attempts to create convenience symlinks in `/usr/local/bin` if you have write permissions.

## Performance Optimization

For optimal performance, install ripgrep:

```bash
# Ubuntu/Debian
sudo apt install ripgrep

# Fedora/RHEL/CentOS
sudo dnf install ripgrep

# macOS
brew install ripgrep

# Arch Linux
sudo pacman -S ripgrep
```

See [ripgrep installation guide](https://github.com/BurntSushi/ripgrep#installation) for additional platforms.

## Usage

### Basic Syntax

```bash
xgrep [options] [ripgrep_options] pattern [directory]
```

### File Detection Examples

xgrep finds files using multiple detection methods:

```bash
# Files found by extension (.py, .sh, .php)
./script.py
./deploy.sh  
./config.php

# Files found by shebang (no extension needed)
./build-script     # #!/bin/bash
./web-tool         # #!/usr/bin/env python3
./cli-app          # #!/usr/bin/php

# Files found by MIME type analysis
./configure        # detected as shell script
./setup            # detected as Python script
```

### Language-Specific Examples

```bash
# Find function definitions in Bash scripts
bashgrep "^function " ~/scripts

# Search for class declarations in PHP files
phpgrep "class [A-Z]" ~/webproject

# Find import statements in Python code
pygrep "^import|^from.*import" ~/python-projects

# Search for TODO comments across all supported languages
xgrep "TODO:|FIXME:" ~/development

# Case-sensitive search for specific error handling
bashgrep "(?-i)ERROR" ~/scripts

# Search with file listing only
pygrep -l "import requests" ~/projects
```

### Advanced Usage

```bash
# Limit search depth and exclude specific directories
xgrep -d 2 -X "venv,node_modules" "api_key" ~/projects

# Reset exclusions and search everything
bashgrep -X '' "#!/bin/bash" ~/

# Use ripgrep options directly
phpgrep --rg -C 3 -n "class.*Controller" ~/webapp

# Debug mode to see what's happening
xgrep -D "pattern" ~/code
```

## Configuration Options

### Command-Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `-d, --maxdepth N` | Limit search depth | `-d 3` |
| `-X, --exclude-dir DIR[,...]` | Exclude directories | `-X "tmp,cache"` |
| `-D, --debug` | Show debug information | `-D` |
| `-V, --version` | Display version | `-V` |
| `--help` | Show help message | `--help` |
| `--`, `--rg` | Pass options to ripgrep | `--rg -C 2 -n` |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `XGREP_EXCLUDE_DIRS` | Override excluded directories | `.venv .git bak temp tmp .tmp .temp .Trash-0` |

### File Detection

The tools intelligently detect files through:

1. **Extensions**: `.sh`, `.bash` (Bash) • `.php`, `.phtml` (PHP) • `.py`, `.pyw` (Python)
2. **Shebangs**: `#!/bin/bash`, `#!/usr/bin/php`, `#!/usr/bin/python3`, etc.
3. **Exclusions**: Common build/dependency directories automatically skipped

## Integration Examples

### Git Hooks

```bash
# Pre-commit hook to find debugging statements
#!/bin/bash
if pygrep -q "pdb\.set_trace|breakpoint\(\)" .; then
    echo "✗ Debugging statements found in Python files"
    exit 1
fi
```

### Build Scripts

```bash
# Check for TODOs before release
if xgrep -q "TODO:|FIXME:" src/; then
    echo "▲ Outstanding TODOs found"
    xgrep "TODO:|FIXME:" src/
fi
```

### Development Workflow

```bash
# Find all error handling patterns
bashgrep "trap|set -e" scripts/
phpgrep "try\s*{|catch\s*\(" src/
pygrep "try:|except|raise" app/
```

## Testing

Run the comprehensive test suite:

```bash
# Run all tests
make test

# Run specific test categories  
make test-unit
make test-integration

# Verbose test output
make test-verbose
```

See [TESTING.md](TESTING.md) for detailed testing information.

## Contributing

We welcome contributions! Please see our [development guide](CLAUDE.md) for:

- Development environment setup
- Code conventions and style
- Testing requirements
- Pull request process

### Quick Development Setup

```bash
# Clone and setup
git clone https://github.com/Open-Technology-Foundation/xgrep.git
cd xgrep

# Install development dependencies
make check-deps

# Run linting and tests
make lint test
```

## Requirements

- **Bash** 4.0+ (for associative arrays and modern features)
- **ripgrep** (recommended for performance) or **grep** + **find**
- **BATS** (for running tests)

## Known Issues & Limitations

- **Shebang Detection**: Limited by ripgrep's built-in file type definitions
- **Symlink Handling**: Follows symlinks; may cause duplicate results in some cases
- **Performance**: Fallback mode significantly slower than ripgrep on large codebases

See our [issue tracker](https://github.com/Open-Technology-Foundation/xgrep/issues) for current bugs and feature requests.

## License

This project is licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for details.

## Author

**Gary Dean** - Open Technology Foundation

## Related Projects

- [ripgrep](https://github.com/BurntSushi/ripgrep) - The fast search engine that powers xgrep
- [ag (The Silver Searcher)](https://github.com/ggreer/the_silver_searcher) - Similar tool with different focus
- [ack](https://github.com/beyondgrep/ack3) - Another grep alternative

---

**◉ Pro Tip**: Use `xgrep -D pattern directory` to see exactly how your search is being executed and what files are being examined.