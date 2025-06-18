#!/bin/bash
# Mock command utilities for testing xgrep

# Create a mock ripgrep that behaves predictably for tests
create_mock_ripgrep() {
    local behavior="${1:-success}"
    local mock_bin_dir="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$mock_bin_dir"
    
    case "$behavior" in
        "success")
            # Mock rg that returns predictable results
            cat > "$mock_bin_dir/rg" << 'EOF'
#!/bin/bash
# Mock ripgrep for testing

# Parse basic options
declare -a types=()
declare -a globs=()
declare pattern=""
declare directory="."
declare -i smart_case=0
declare -i color=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type=*)
            types+=("${1#--type=}")
            ;;
        --glob)
            shift
            globs+=("$1")
            ;;
        --smart-case)
            smart_case=1
            ;;
        --color=auto)
            color=1
            ;;
        --max-depth)
            shift # skip depth value
            shift
            continue
            ;;
        -*)
            # Skip other options
            ;;
        *)
            if [[ -z "$pattern" ]]; then
                pattern="$1"
            else
                directory="$1"
            fi
            ;;
    esac
    shift
done

# Simple mock search - find files and grep pattern
find "$directory" -type f -name "*.sh" -o -name "*.bash" -o -name "*.php" -o -name "*.py" 2>/dev/null | \
while read -r file; do
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "$file:$(grep "$pattern" "$file" | head -1)"
    fi
done
EOF
            ;;
        "not_found")
            # Don't create rg command to simulate absence
            return 0
            ;;
        "failure")
            # Mock rg that always fails
            cat > "$mock_bin_dir/rg" << 'EOF'
#!/bin/bash
echo "ripgrep failed" >&2
exit 2
EOF
            ;;
    esac
    
    chmod +x "$mock_bin_dir/rg" 2>/dev/null || true
    export PATH="$mock_bin_dir:$PATH"
}

# Create mock grep that can simulate failures
create_mock_grep() {
    local behavior="${1:-success}"
    local mock_bin_dir="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$mock_bin_dir"
    
    case "$behavior" in
        "success")
            # Use real grep
            ln -sf "$(command -v grep)" "$mock_bin_dir/grep"
            ;;
        "failure")
            cat > "$mock_bin_dir/grep" << 'EOF'
#!/bin/bash
echo "grep failed" >&2
exit 2
EOF
            ;;
        "no_matches")
            cat > "$mock_bin_dir/grep" << 'EOF'
#!/bin/bash
exit 1
EOF
            ;;
    esac
    
    chmod +x "$mock_bin_dir/grep" 2>/dev/null || true
    export PATH="$mock_bin_dir:$PATH"
}

# Create mock find that can simulate failures
create_mock_find() {
    local behavior="${1:-success}"
    local mock_bin_dir="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$mock_bin_dir"
    
    case "$behavior" in
        "success")
            # Use real find
            ln -sf "$(command -v find)" "$mock_bin_dir/find"
            ;;
        "failure")
            cat > "$mock_bin_dir/find" << 'EOF'
#!/bin/bash
echo "find: permission denied" >&2
exit 1
EOF
            ;;
        "empty")
            cat > "$mock_bin_dir/find" << 'EOF'
#!/bin/bash
# Return no files
exit 0
EOF
            ;;
    esac
    
    chmod +x "$mock_bin_dir/find" 2>/dev/null || true
    export PATH="$mock_bin_dir:$PATH"
}

# Reset to use real commands
reset_commands() {
    export PATH="$ORIGINAL_PATH"
}