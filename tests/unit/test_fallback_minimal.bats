#!/usr/bin/env bats
# Minimal unit tests for xgrep fallback logic

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    create_simple_test_files
}

teardown() {
    teardown_test_env
}

create_simple_test_files() {
    mkdir -p "$TEST_TEMP_DIR/testdir"
    echo "test_pattern_here" > "$TEST_TEMP_DIR/testdir/test.sh"
    echo "<?php echo 'test_pattern_here';" > "$TEST_TEMP_DIR/testdir/test.php"
    echo "print('test_pattern_here')" > "$TEST_TEMP_DIR/testdir/test.py"
}

# Test that normal mode uses ripgrep
@test "normal mode detects ripgrep availability" {
    run_as_program "xgrep" "-D" "test_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "DEBUG: RG_CMD=rg" ]]
}


# Test that fallback mode can find files - use RG_CMD env var
@test "fallback mode finds test pattern when ripgrep unavailable" {
    export RG_CMD=grep_fallback
    run_as_program "xgrep" "test_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "test.sh" ]]
    [[ "$output" =~ "test.php" ]]
    [[ "$output" =~ "test.py" ]]
}

# Test language-specific filtering in fallback mode
@test "fallback mode respects language filtering when ripgrep unavailable" {
    export RG_CMD=grep_fallback
    run_as_program "bashgrep" "test_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "test.sh" ]]
    [[ ! "$output" =~ "test.php" ]]
    [[ ! "$output" =~ "test.py" ]]
}

# Test debug output in fallback mode
@test "fallback mode shows proper debug information when ripgrep unavailable" {
    export RG_CMD=grep_fallback
    run_as_program "xgrep" "-D" "test_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "DEBUG: Fallback mode with advanced file detection" ]]
    [[ "$output" =~ "DEBUG: mode_filter=" ]]
    [[ "$output" =~ "DEBUG: grep_opts=" ]]
}

# Test error handling in fallback mode
@test "fallback mode handles no matches gracefully when ripgrep unavailable" {
    export RG_CMD=grep_fallback
    run_as_program "xgrep" "nonexistent_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 1 ]]
}

@test "fallback mode handles empty directory when ripgrep unavailable" {
    export RG_CMD=grep_fallback
    # Create truly empty directory (no script files)
    mkdir -p "$TEST_TEMP_DIR/truly_empty"
    run_as_program "xgrep" "test_pattern" "$TEST_TEMP_DIR/truly_empty"
    [[ $status -eq 1 ]]
    [[ "$output" =~ No.*files\ found ]]
}

# Test exclude directory functionality in fallback mode
@test "fallback mode respects exclude directory option when ripgrep unavailable" {
    export RG_CMD=grep_fallback
    mkdir -p "$TEST_TEMP_DIR/testdir/.git"
    echo "test_pattern_here" > "$TEST_TEMP_DIR/testdir/.git/config"

    run_as_program "xgrep" "test_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    # Should find in main files but not in .git
    [[ "$output" =~ "test.sh" ]]
    [[ ! "$output" =~ ".git/config" ]]
}

# Test maxdepth functionality in fallback mode
@test "fallback mode respects maxdepth option when ripgrep unavailable" {
    export RG_CMD=grep_fallback
    mkdir -p "$TEST_TEMP_DIR/testdir/deep"
    echo "test_pattern_here" > "$TEST_TEMP_DIR/testdir/deep/deep.sh"

    run_as_program "xgrep" "-d" "1" "test_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    # Should find in root level but not in deep subdirectory
    [[ "$output" =~ "test.sh" ]]
    [[ ! "$output" =~ "deep/deep.sh" ]]
}