#!/usr/bin/env bats
# Unit tests for xgrep fallback logic (grep+find when ripgrep not available)

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    create_fallback_test_environment
}

teardown() {
    teardown_test_env
}

create_fallback_test_environment() {
    # Create test files for fallback testing
    mkdir -p "$TEST_TEMP_DIR/testdir"
    create_test_file "testdir/script.sh" "echo 'fallback test pattern'" "#!/bin/bash"
    create_test_file "testdir/web.php" "<?php echo 'fallback test pattern';"
    create_test_file "testdir/app.py" "print('fallback test pattern')" "#!/usr/bin/env python3"
    create_test_file "testdir/readme.txt" "This should not match"
    
    # Create excluded directory
    mkdir -p "$TEST_TEMP_DIR/testdir/.git"
    create_test_file "testdir/.git/config" "fallback test pattern"
}

# Test fallback mode activation
@test "fallback mode activates when ripgrep not available" {
    mock_no_ripgrep
    run_as_program "xgrep" "-D" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "Warning: ripgrep.*not found" ]]
    [[ "$output" =~ "Falling back to standard grep" ]]
}

@test "fallback mode uses find+grep successfully" {
    mock_no_ripgrep
    run_as_program "xgrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    # Should find pattern in all three file types
    [[ "$output" =~ "script.sh" ]]
    [[ "$output" =~ "web.php" ]]
    [[ "$output" =~ "app.py" ]]
}

@test "fallback mode respects language filters - bash only" {
    mock_no_ripgrep
    run_as_program "bashgrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "web.php" ]]
    [[ ! "$output" =~ "app.py" ]]
}

@test "fallback mode respects language filters - php only" {
    mock_no_ripgrep
    run_as_program "phpgrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ ! "$output" =~ "script.sh" ]]
    [[ "$output" =~ "web.php" ]]
    [[ ! "$output" =~ "app.py" ]]
}

@test "fallback mode respects language filters - python only" {
    mock_no_ripgrep
    run_as_program "pygrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ ! "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "web.php" ]]
    [[ "$output" =~ "app.py" ]]
}

@test "fallback mode excludes default directories" {
    mock_no_ripgrep
    run_as_program "xgrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    # Should not find pattern in .git directory
    [[ ! "$output" =~ ".git/config" ]]
}

@test "fallback mode handles maxdepth option" {
    mock_no_ripgrep
    mkdir -p "$TEST_TEMP_DIR/testdir/deep/deeper"
    create_test_file "testdir/deep/deeper/deep.sh" "fallback test pattern" "#!/bin/bash"
    
    run_as_program "xgrep" "-d" "1" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    # Should not find the deeply nested file
    [[ ! "$output" =~ "deep.sh" ]]
}

@test "fallback mode handles exclude directory option" {
    mock_no_ripgrep
    mkdir -p "$TEST_TEMP_DIR/testdir/excluded"
    create_test_file "testdir/excluded/test.sh" "fallback test pattern" "#!/bin/bash"
    
    run_as_program "xgrep" "-X" "excluded" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    # Should not find pattern in excluded directory
    [[ ! "$output" =~ "excluded/test.sh" ]]
}

@test "fallback mode shows debug information when requested" {
    mock_no_ripgrep
    run_as_program "xgrep" "-D" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "DEBUG: Fallback mode with find+grep" ]]
    [[ "$output" =~ "DEBUG: find_opts=" ]]
    [[ "$output" =~ "DEBUG: grep_opts=" ]]
}

# Test error conditions in fallback mode
@test "fallback mode handles no files found gracefully" {
    mock_no_ripgrep
    mkdir -p "$TEST_TEMP_DIR/empty"
    run_as_program "xgrep" "nonexistent" "$TEST_TEMP_DIR/empty"
    [[ $status -eq 1 ]]
    [[ "$output" =~ "No files found" ]]
}

@test "fallback mode handles no matches found" {
    mock_no_ripgrep
    run_as_program "xgrep" "nonexistent_pattern" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 1 ]]
    [[ "$output" =~ "No.*files found with pattern" ]]
}

# Test that regular mode still works with ripgrep available
@test "regular mode uses ripgrep when available" {
    create_mock_ripgrep "success"
    run_as_program "xgrep" "-D" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "DEBUG: RG_CMD=rg" ]]
    [[ ! "$output" =~ "Warning.*ripgrep.*not found" ]]
}


# Test specific ripgrep option conversion in fallback mode
@test "fallback mode converts --type options correctly" {
    mock_no_ripgrep
    run_as_program "xgrep" "-D" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "DEBUG: find_type_opts=" ]]
    # Should have converted --type=sh to find options
    [[ "$output" =~ "*.sh" || "$output" =~ "*.bash" ]]
}

@test "fallback mode handles smart-case option" {
    mock_no_ripgrep
    run_as_program "xgrep" "-D" "FALLBACK" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    # Should find pattern regardless of case due to smart-case conversion
}

# Test file type detection logic
@test "fallback mode finds bash files by extension and shebang" {
    mock_no_ripgrep
    # Create bash file without extension but with shebang
    create_test_file "testdir/bash_script" "fallback test pattern" "#!/bin/bash"
    
    run_as_program "bashgrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "script.sh" ]]  # Extension-based
    [[ "$output" =~ "bash_script" ]]  # Shebang-based
}

@test "fallback mode finds php files by extension and shebang" {
    mock_no_ripgrep
    # Create PHP file without extension but with shebang
    create_test_file "testdir/php_cli" "<?php echo 'fallback test pattern';" "#!/usr/bin/env php"
    
    run_as_program "phpgrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "web.php" ]]  # Extension-based
    [[ "$output" =~ "php_cli" ]]  # Shebang-based
}

@test "fallback mode finds python files by extension and shebang" {
    mock_no_ripgrep
    # Create Python file without extension but with shebang
    create_test_file "testdir/py_script" "print('fallback test pattern')" "#!/usr/bin/env python3"
    
    run_as_program "pygrep" "fallback" "$TEST_TEMP_DIR/testdir"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "app.py" ]]  # Extension-based
    [[ "$output" =~ "py_script" ]]  # Shebang-based
}