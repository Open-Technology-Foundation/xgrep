#!/bin/bash
# Test setup helpers for xgrep test suite

# Get absolute path to xgrep script
export XGREP_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/xgrep"
export XGREP_DIR="$(dirname "$XGREP_SCRIPT")"

# Test fixture directories
export TEST_FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../fixtures" && pwd)"
export TEST_FILES_DIR="$TEST_FIXTURES_DIR/test_files"
export EXPECTED_OUTPUTS_DIR="$TEST_FIXTURES_DIR/expected_outputs"

# Temporary directory for test isolation
export TEST_TEMP_DIR="${BATS_TMPDIR:-/tmp}/xgrep-tests-$$"

setup_test_env() {
    # Create isolated test environment
    mkdir -p "$TEST_TEMP_DIR"
    cd "$TEST_TEMP_DIR"
    
    # Reset environment variables that could affect tests
    unset XGREP_EXCLUDE_DIRS
    unset RG_CMD
    
    # Create test PATH that may or may not include ripgrep
    export ORIGINAL_PATH="$PATH"
}

teardown_test_env() {
    # Restore original environment
    export PATH="$ORIGINAL_PATH"
    
    # Clean up temporary directory
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper to create a temporary file with specific content
create_test_file() {
    local filename="$1"
    local content="$2"
    local shebang="$3"
    
    local filepath="$TEST_TEMP_DIR/$filename"
    mkdir -p "$(dirname "$filepath")"
    
    if [[ -n "$shebang" ]]; then
        echo "$shebang" > "$filepath"
        echo "$content" >> "$filepath"
    else
        echo "$content" > "$filepath"
    fi
    
    chmod +x "$filepath"
    echo "$filepath"
}

# Helper to mock ripgrep absence
mock_no_ripgrep() {
    # Create a temporary PATH without rg or ripgrep
    local temp_bin_dir="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$temp_bin_dir"
    
    # Copy essential commands but exclude ripgrep
    for cmd in find grep cat ls mkdir ln dirname basename chmod echo printf bash sh; do
        if command -v "$cmd" >/dev/null 2>&1; then
            ln -sf "$(command -v "$cmd")" "$temp_bin_dir/$cmd"
        fi
    done
    
    export PATH="$temp_bin_dir"
}

# Helper to mock command failures
create_failing_command() {
    local cmd_name="$1"
    local exit_code="${2:-1}"
    local error_msg="${3:-Command failed}"
    
    local mock_bin_dir="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$mock_bin_dir"
    
    cat > "$mock_bin_dir/$cmd_name" << EOF
#!/bin/bash
echo "$error_msg" >&2
exit $exit_code
EOF
    chmod +x "$mock_bin_dir/$cmd_name"
    export PATH="$mock_bin_dir:$PATH"
}

# Helper to capture stderr
capture_stderr() {
    "$@" 2>"$TEST_TEMP_DIR/stderr.log"
    cat "$TEST_TEMP_DIR/stderr.log"
}

# Helper to run xgrep with specific program name
run_as_program() {
    local prog_name="$1"
    shift
    
    local temp_script="$TEST_TEMP_DIR/$prog_name"
    ln -sf "$XGREP_SCRIPT" "$temp_script"
    run "$temp_script" "$@"
}

# Helper to check if output contains expected patterns
output_contains() {
    local pattern="$1"
    echo "$output" | grep -q "$pattern"
}

# Helper to normalize output for comparison (remove paths, line numbers)
normalize_output() {
    echo "$1" | sed 's|^[^:]*:||g' | sort
}

# Assertion helpers
assert_success() {
    if [[ $status -ne 0 ]]; then
        echo "Expected success (exit code 0) but got $status"
        echo "Output: $output"
        return 1
    fi
}

assert_failure() {
    if [[ $status -eq 0 ]]; then
        echo "Expected failure (non-zero exit code) but got success"
        echo "Output: $output"
        return 1
    fi
}

assert_output_contains() {
    local expected="$1"
    if ! echo "$output" | grep -q "$expected"; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

assert_output_not_contains() {
    local unexpected="$1"
    if echo "$output" | grep -q "$unexpected"; then
        echo "Expected output NOT to contain: $unexpected"
        echo "Actual output: $output"
        return 1
    fi
}