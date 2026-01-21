#!/usr/bin/env bats
# Minimal unit tests for xgrep argument parsing logic

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env

    # Create test directory with test files
    mkdir -p "$TEST_TEMP_DIR/testdir"
    echo "test pattern here" > "$TEST_TEMP_DIR/testdir/test.sh"
    echo "<?php echo 'test pattern';" > "$TEST_TEMP_DIR/testdir/test.php"
    echo "print('test pattern')" > "$TEST_TEMP_DIR/testdir/test.py"
}

teardown() {
    teardown_test_env
}

# Test help and version (these work predictably)
@test "help option works and shows usage" {
    run_as_program "xgrep" "--help"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "USAGE" ]]
}

@test "version option shows version number" {
    run_as_program "xgrep" "-V"
    [[ $status -eq 0 ]]
    [[ "${output##*$'\n'}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Test error conditions (checking exit codes)
@test "no arguments shows help" {
    run_as_program "xgrep"
    [[ $status -eq 1 ]]
}

@test "invalid maxdepth fails with correct exit code" {
    run_as_program "xgrep" "-d" "invalid" "pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 2 ]]
}

@test "missing directory fails correctly" {
    run_as_program "xgrep" "pattern" "/nonexistent"
    [[ $status -eq 1 ]]
}

@test "empty pattern fails correctly" {
    run_as_program "xgrep" "" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 1 ]]
}

# Test successful cases with test directory
@test "valid maxdepth argument succeeds" {
    run_as_program "xgrep" "-d" "1" "pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
}

@test "debug mode enables debug output" {
    run_as_program "xgrep" "-D" "pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "DEBUG:" ]]
}

@test "exclude directory option accepted" {
    run_as_program "xgrep" "-X" "somedir" "pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
}

# Test program name detection through symlinks
@test "phpgrep symlink detected correctly in help" {
    run_as_program "phpgrep" "--help"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "phpgrep" ]]
    [[ "$output" =~ "Language-Specific Grep Tool" ]]
}

@test "bashgrep symlink detected correctly in help" {
    run_as_program "bashgrep" "--help"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "bashgrep" ]]
    [[ "$output" =~ "Language-Specific Grep Tool" ]]
}

@test "pygrep symlink detected correctly in help" {
    run_as_program "pygrep" "--help"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "pygrep" ]]
    [[ "$output" =~ "Language-Specific Grep Tool" ]]
}