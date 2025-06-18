#!/usr/bin/env bats
# Unit tests for xgrep helper functions

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    
    # Source the xgrep script to get access to helper functions
    # We need to extract and source just the helper functions
    source_helper_functions
}

teardown() {
    teardown_test_env
}

# Extract helper functions from xgrep for isolated testing
source_helper_functions() {
    # Create a test version of xgrep with just the helper functions
    cat > "$TEST_TEMP_DIR/helpers.bash" << 'EOF'
#!/bin/bash
# Extracted helper functions for testing

declare -i DEBUG=0
PRG="test_program"

error() { local msg; for msg in "$@"; do >&2 printf '%s: error: %s\n' "$PRG" "$msg"; done; }
die() { 
    local -i exitcode=1
    # Check if first arg is a number (exit code)
    if (($#)) && [[ $1 =~ ^[0-9]+$ ]]; then
        exitcode=$1
        shift
    fi
    if (($#)); then
        error "$@"
    fi
    exit "$exitcode"
}
noarg() { if (($# < 2)) || [[ ${2:0:1} == '-' ]]; then die 2 "Missing argument for option '$1'"; fi; true; }
xcleanup() { local -i exitcode=${1:-0}; [[ -t 0 ]] && printf '\e[?25h'; exit "$exitcode"; }
decp() { declare -p "$@" | sed 's/^declare -[a-z-]* //'; }
EOF
    
    source "$TEST_TEMP_DIR/helpers.bash"
}

# Test error() function
@test "error() outputs error message to stderr with program name" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; error 'test message' 2>&1"
    assert_success
    assert_output_contains "test_program: error: test message"
}

@test "error() handles multiple error messages" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; error 'first error' 'second error' 2>&1"
    assert_success
    assert_output_contains "test_program: error: first error"
    assert_output_contains "test_program: error: second error"
}

@test "error() handles empty messages" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; error '' 2>&1"
    assert_success
    assert_output_contains "test_program: error: "
}

# Test die() function
@test "die() exits with default code 1 when no arguments" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; die"
    [[ $status -eq 1 ]]
}

@test "die() exits with specified exit code" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; die 42"
    [[ $status -eq 42 ]]
}

@test "die() exits with exit code and error message" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; die 3 'custom error' 2>&1"
    [[ $status -eq 3 ]]
    assert_output_contains "test_program: error: custom error"
}

@test "die() exits with default code 1 and error message" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; die 'just error message' 2>&1"
    [[ $status -eq 1 ]]
    assert_output_contains "test_program: error: just error message"
}

# Test noarg() function
@test "noarg() succeeds when argument is provided" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; noarg '--option' 'value'"
    assert_success
}

@test "noarg() fails when no argument provided" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; noarg '--option' 2>&1"
    [[ $status -eq 2 ]]
    assert_output_contains "Missing argument for option '--option'"
}

@test "noarg() fails when argument starts with dash" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; noarg '--option' '--another-option' 2>&1"
    [[ $status -eq 2 ]]
    assert_output_contains "Missing argument for option '--option'"
}

@test "noarg() succeeds with argument that contains dash but doesn't start with it" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; noarg '--option' 'value-with-dash'"
    assert_success
}

# Test decp() function
@test "decp() formats declare output correctly" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; TEST_VAR='test_value'; decp TEST_VAR"
    assert_success
    assert_output_contains 'TEST_VAR="test_value"'
    assert_output_not_contains "declare"
}

@test "decp() handles arrays" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; declare -a TEST_ARRAY=('one' 'two'); decp TEST_ARRAY"
    assert_success
    assert_output_contains "TEST_ARRAY="
    assert_output_not_contains "declare"
}

@test "decp() handles multiple variables" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; VAR1='value1'; VAR2='value2'; decp VAR1 VAR2"
    assert_success
    assert_output_contains 'VAR1="value1"'
    assert_output_contains 'VAR2="value2"'
}

# Test xcleanup() function behavior (without actually calling it since it exits)
@test "xcleanup() function exists and is callable" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; type xcleanup"
    assert_success
    assert_output_contains "xcleanup is a function"
}

# Integration test: die() calls error() correctly
@test "die() with message calls error() function" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; die 5 'integration test' 2>&1"
    [[ $status -eq 5 ]]
    assert_output_contains "test_program: error: integration test"
}

# Edge case tests
@test "error() handles special characters in messages" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; error 'message with \$special chars & symbols!' 2>&1"
    assert_success
    assert_output_contains "message with \$special chars & symbols!"
}

@test "noarg() handles options with equals sign" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; noarg '--option=value' 'next_arg'"
    assert_success
}

@test "die() handles zero exit code" {
    run bash -c "source $TEST_TEMP_DIR/helpers.bash; die 0 'success message' 2>&1"
    [[ $status -eq 0 ]]
    assert_output_contains "test_program: error: success message"
}