#!/usr/bin/env bats
# Unit tests for xgrep argument parsing logic

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    create_test_files
}

teardown() {
    teardown_test_env
}

create_test_files() {
    # Create some basic test files in a subdirectory to avoid noise
    mkdir -p "$TEST_TEMP_DIR/testfiles"
    create_test_file "testfiles/test.sh" "echo 'test pattern'" "#!/bin/bash"
    create_test_file "testfiles/test.php" "<?php echo 'test pattern';"
    create_test_file "testfiles/test.py" "print('test pattern')" "#!/usr/bin/env python3"
}

# Test basic argument parsing
@test "parses simple pattern and directory" {
    run_as_program "xgrep" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "uses current directory when no directory specified" {
    cd "$TEST_TEMP_DIR"
    run_as_program "xgrep" "pattern"
    assert_success
}

@test "fails when no pattern provided" {
    run_as_program "xgrep"
    assert_failure
    [[ $status -eq 1 ]]
}

@test "fails when too many arguments provided" {
    run_as_program "xgrep" "pattern" "dir1" "dir2"
    assert_failure
    [[ $status -eq 1 ]]
}

# Test help and version options
@test "--help displays help and exits successfully" {
    run_as_program "xgrep" "--help"
    assert_success
    [[ $status -eq 0 ]]
    [[ "$output" =~ "USAGE" ]]
}

@test "-V displays version and exits successfully" {
    run_as_program "xgrep" "-V"
    assert_success
    [[ $status -eq 0 ]]
    [[ "${lines[-1]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "--version displays version and exits successfully" {
    run_as_program "xgrep" "--version"
    assert_success
    [[ $status -eq 0 ]]
    [[ "${lines[-1]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Test maxdepth option
@test "-d option requires numeric argument" {
    run_as_program "xgrep" "-d" "not_a_number" "pattern" "$TEST_TEMP_DIR"
    [[ $status -eq 2 ]]
    [[ "$output" =~ "maxdepth must be a non-negative integer" ]]
}

@test "--maxdepth option accepts valid numbers" {
    run_as_program "xgrep" "--maxdepth" "2" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "-d option fails when no argument provided" {
    # Test with another option immediately following -d
    run_as_program "xgrep" "-d" "-X" "somedir" "pattern" "$TEST_TEMP_DIR"
    assert_failure
    [[ $status -eq 22 ]]
    assert_output_contains "Option '-d' requires an argument"
}

@test "maxdepth accepts zero" {
    # maxdepth=0 is a valid argument (no validation error)
    # but finds no files since depth 0 = directory entry only
    run_as_program "xgrep" "-d" "0" "pattern" "$TEST_TEMP_DIR"
    # Should exit 1 (no files found), not 2 (error) - verifies 0 is accepted
    [[ $status -eq 1 ]]
}

@test "maxdepth rejects negative numbers" {
    # -1 looks like an option, so noarg rejects it (exit 22)
    # This is correct behavior - prevents ambiguous parsing
    run_as_program "xgrep" "-d" "-1" "pattern" "$TEST_TEMP_DIR"
    assert_failure
    [[ $status -eq 22 ]]
}

# Test exclude directory options
@test "-X option excludes directories" {
    run_as_program "xgrep" "-X" "test_dir" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "--exclude-dir option excludes directories" {
    run_as_program "xgrep" "--exclude-dir" "test_dir" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "-X option can reset exclusions with empty string" {
    run_as_program "xgrep" "-X" "" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "-X option accepts comma-separated directories" {
    run_as_program "xgrep" "-X" "dir1,dir2,dir3" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "-X option fails when no argument provided" {
    # Test with another option immediately following -X
    run_as_program "xgrep" "-X" "-d" "1" "pattern" "$TEST_TEMP_DIR"
    assert_failure
    [[ $status -eq 22 ]]
    assert_output_contains "Option '-X' requires an argument"
}

# Test debug option
@test "-D enables debug mode" {
    run_as_program "xgrep" "-D" "pattern" "$TEST_TEMP_DIR"
    assert_success
    assert_output_contains "DEBUG:"
}

@test "--debug enables debug mode" {
    run_as_program "xgrep" "--debug" "pattern" "$TEST_TEMP_DIR"
    assert_success
    assert_output_contains "DEBUG:"
}

# Test ripgrep passthrough options
@test "-- passes remaining options to ripgrep" {
    # Pattern and directory come before --, extra rg options after
    run_as_program "xgrep" "pattern" "$TEST_TEMP_DIR" "--" "--ignore-case"
    assert_success
}

@test "--rg passes remaining options to ripgrep" {
    # Pattern and directory come before --rg, extra rg options after
    run_as_program "xgrep" "pattern" "$TEST_TEMP_DIR" "--rg" "--ignore-case"
    assert_success
}

# Test that unknown short options are passed to ripgrep
@test "unknown short options passed to ripgrep" {
    run_as_program "xgrep" "-i" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "unknown long options passed to ripgrep" {
    run_as_program "xgrep" "--ignore-case" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

# Test option ordering
@test "options can come before pattern" {
    run_as_program "xgrep" "-D" "-d" "2" "pattern" "$TEST_TEMP_DIR"
    assert_success
    assert_output_contains "DEBUG:"
}

@test "options can come after pattern" {
    run_as_program "xgrep" "pattern" "-D" "$TEST_TEMP_DIR"
    assert_success
    assert_output_contains "DEBUG:"
}

@test "mixed option placement works" {
    # Use depth 2 to reach files in testfiles/ subdirectory
    run_as_program "xgrep" "-D" "pattern" "-d" "2" "$TEST_TEMP_DIR"
    assert_success
    assert_output_contains "DEBUG:"
}

# Test directory validation
@test "fails when directory does not exist" {
    run_as_program "xgrep" "pattern" "/nonexistent/directory"
    assert_failure
    [[ $status -eq 1 ]]
    assert_output_contains "Directory '/nonexistent/directory' does not exist"
}

@test "accepts relative directory paths" {
    mkdir -p "$TEST_TEMP_DIR/subdir"
    # Create a test file in the subdir
    echo "test pattern" > "$TEST_TEMP_DIR/subdir/test.sh"
    cd "$TEST_TEMP_DIR"
    run_as_program "xgrep" "pattern" "subdir"
    assert_success
}

@test "accepts absolute directory paths" {
    run_as_program "xgrep" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

# Test pattern validation
@test "fails when pattern is empty string" {
    run_as_program "xgrep" "" "$TEST_TEMP_DIR"
    assert_failure
    [[ $status -eq 1 ]]
    assert_output_contains "Search pattern cannot be empty"
}

@test "accepts pattern with special characters" {
    run_as_program "xgrep" "test.*pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "accepts pattern with spaces" {
    run_as_program "xgrep" "test pattern" "$TEST_TEMP_DIR"
    assert_success
}

# Test environment variable handling
@test "XGREP_EXCLUDE_DIRS environment variable affects exclusions" {
    export XGREP_EXCLUDE_DIRS="custom_exclude"
    run_as_program "xgrep" "-D" "pattern" "$TEST_TEMP_DIR"
    assert_success
    assert_output_contains "exclude_dirs=custom_exclude"
}

@test "empty XGREP_EXCLUDE_DIRS works correctly" {
    export XGREP_EXCLUDE_DIRS=""
    run_as_program "xgrep" "-D" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

# Test multiple exclude directory options
@test "multiple -X options work correctly" {
    run_as_program "xgrep" "-X" "dir1" "-X" "dir2" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

# Test complex argument combinations
@test "complex argument combination works" {
    export XGREP_EXCLUDE_DIRS="env_exclude"
    run_as_program "xgrep" "-D" "--maxdepth" "3" "-X" "manual_exclude" "--ignore-case" "test" "$TEST_TEMP_DIR"
    assert_success
    assert_output_contains "DEBUG:"
}

# Test edge cases for numeric validation
@test "maxdepth accepts large numbers" {
    run_as_program "xgrep" "-d" "999999" "pattern" "$TEST_TEMP_DIR"
    assert_success
}

@test "maxdepth rejects non-numeric strings" {
    run_as_program "xgrep" "-d" "abc123" "pattern" "$TEST_TEMP_DIR"
    assert_failure
    [[ $status -eq 2 ]]
}

@test "maxdepth rejects floating point numbers" {
    run_as_program "xgrep" "-d" "2.5" "pattern" "$TEST_TEMP_DIR"
    assert_failure
    [[ $status -eq 2 ]]
}