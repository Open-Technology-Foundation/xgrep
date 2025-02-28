# xgrep - Specialized Grep Tools

## Usage Commands
- Run specific language grep (replace `pattern` with search term):
  - `./bashgrep pattern [directory]` - Search in Bash files
  - `./phpgrep pattern [directory]` - Search in PHP files
  - `./pygrep pattern [directory]` - Search in Python files
  - `./xgrep pattern [directory]` - Search in all supported files

## Options
- `-d, --maxdepth N` - Set search depth (default: unlimited)
- `-X, --exclude-dir DIR[,...]` - Exclude directories
- `-D, --debug` - Show debug information
- `-V, --version` - Show version
- `--help` - Display help

## Testing
- Test basic functionality: `./bashgrep test ./test`
- Test with options: `./bashgrep -d 2 -X '' pattern [directory]`

## Performance Notes
- Uses ripgrep (rg) for optimal performance when available
- Falls back to grep+find if ripgrep is not installed
- Install ripgrep for dramatically better performance

## Code Style Guidelines
- Shell scripts follow bash best practices with `set -euo pipefail`
- Use ShellCheck for linting (note disable comments when needed)
- Functions use local variables with explicit declaration
- Error handling with descriptive error messages via `error()` and `die()`
- Variable naming: lowercase with underscores for regular vars, UPPERCASE for constants

## Environment Configuration
- Set `XGREP_EXCLUDE_DIRS` to override default excluded directories
- Set `RG_CMD=grep_fallback` to force use of grep instead of ripgrep