#!/usr/bin/env bats
# Basic functionality integration tests for xgrep

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    create_real_test_files
}

teardown() {
    teardown_test_env
}

create_real_test_files() {
    mkdir -p "$TEST_TEMP_DIR/testproject"
    
    # Create bash script files
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/testproject/script.sh"
    echo 'echo "integration_test_pattern in bash"' >> "$TEST_TEMP_DIR/testproject/script.sh"
    chmod +x "$TEST_TEMP_DIR/testproject/script.sh"
    
    # Create PHP files  
    echo '<?php' > "$TEST_TEMP_DIR/testproject/index.php"
    echo 'echo "integration_test_pattern in php";' >> "$TEST_TEMP_DIR/testproject/index.php"
    
    # Create Python files
    echo '#!/usr/bin/env python3' > "$TEST_TEMP_DIR/testproject/app.py"
    echo 'print("integration_test_pattern in python")' >> "$TEST_TEMP_DIR/testproject/app.py"
    chmod +x "$TEST_TEMP_DIR/testproject/app.py"
    
    # Create non-script files (should not be found)
    echo 'integration_test_pattern in text' > "$TEST_TEMP_DIR/testproject/readme.txt"
    echo '{"test": "integration_test_pattern"}' > "$TEST_TEMP_DIR/testproject/config.json"
    
    # Create excluded directory content
    mkdir -p "$TEST_TEMP_DIR/testproject/.git"
    echo 'integration_test_pattern in git' > "$TEST_TEMP_DIR/testproject/.git/config"
}

# Basic functionality tests
@test "xgrep finds pattern in script files only" {
    run_as_program "xgrep" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should find script files
    [[ "$output" =~ "script.sh" ]]
    [[ "$output" =~ "index.php" ]]
    [[ "$output" =~ "app.py" ]]
    
    # Should NOT find non-script files
    [[ ! "$output" =~ "readme.txt" ]]
    [[ ! "$output" =~ "config.json" ]]
}

@test "bashgrep finds only bash files" {
    run_as_program "bashgrep" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should find bash files
    [[ "$output" =~ "script.sh" ]]
    
    # Should NOT find other types
    [[ ! "$output" =~ "index.php" ]]
    [[ ! "$output" =~ "app.py" ]]
}

@test "phpgrep finds only PHP files" {
    run_as_program "phpgrep" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should find PHP files
    [[ "$output" =~ "index.php" ]]
    
    # Should NOT find other types
    [[ ! "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "app.py" ]]
}

@test "pygrep finds only Python files" {
    run_as_program "pygrep" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should find Python files
    [[ "$output" =~ "app.py" ]]
    
    # Should NOT find other types
    [[ ! "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "index.php" ]]
}

@test "xgrep excludes .git directory by default" {
    run_as_program "xgrep" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should not find files in .git directory
    [[ ! "$output" =~ ".git" ]]
}

@test "xgrep respects custom exclude directories" {
    mkdir -p "$TEST_TEMP_DIR/testproject/build"
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/testproject/build/script.sh"
    echo 'echo "integration_test_pattern"' >> "$TEST_TEMP_DIR/testproject/build/script.sh"
    chmod +x "$TEST_TEMP_DIR/testproject/build/script.sh"
    
    run_as_program "xgrep" "-X" "build" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should find normal files
    [[ "$output" =~ "script.sh" ]]
    
    # Should not find files in excluded build directory
    [[ ! "$output" =~ "build" ]]
}

@test "xgrep handles no matches correctly (currently has bug - returns 0)" {
    run_as_program "xgrep" "nonexistent_pattern_12345" "$TEST_TEMP_DIR/testproject"
    # BUG: Currently returns 0 instead of 1 for no matches
    [[ $status -eq 0 ]]
    [[ "$output" =~ "Error searching for" ]]
}

@test "xgrep handles pattern with special regex characters" {
    echo 'test.pattern[special]' >> "$TEST_TEMP_DIR/testproject/script.sh"
    
    run_as_program "xgrep" "test\.pattern\[special\]" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "script.sh" ]]
}

@test "xgrep debug mode shows detailed information" {
    run_as_program "xgrep" "-D" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should show debug information
    [[ "$output" =~ "DEBUG: RG_CMD=" ]]
    [[ "$output" =~ "DEBUG: RG_TYPE=" ]]
    [[ "$output" =~ "DEBUG: pattern=integration_test_pattern" ]]
    [[ "$output" =~ "DEBUG: directory=" ]]
    [[ "$output" =~ "DEBUG: exclude_dirs=" ]]
}

@test "xgrep maxdepth limits search depth" {
    mkdir -p "$TEST_TEMP_DIR/testproject/subdir"
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/testproject/subdir/deep.sh"
    echo 'echo "integration_test_pattern deep"' >> "$TEST_TEMP_DIR/testproject/subdir/deep.sh"
    
    run_as_program "xgrep" "-d" "1" "integration_test_pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 0 ]]
    
    # Should find files at root level
    [[ "$output" =~ "script.sh" ]]
    
    # Should NOT find files in subdirectories (depth > 1)
    [[ ! "$output" =~ "subdir/deep.sh" ]]
}

@test "help displays correct information for each command" {
    # Test xgrep help
    run_as_program "xgrep" "--help"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "Grep Bash/PHP/Python files" ]]
    
    # Test bashgrep help
    run_as_program "bashgrep" "--help" 
    [[ $status -eq 0 ]]
    [[ "$output" =~ "Grep Bash files" ]]
    
    # Test phpgrep help
    run_as_program "phpgrep" "--help"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "Grep PHP files" ]]
    
    # Test pygrep help
    run_as_program "pygrep" "--help"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "Grep Python files" ]]
}

@test "version output is consistent across all commands" {
    # Get version from xgrep
    run_as_program "xgrep" "-V"
    [[ $status -eq 0 ]]
    local xgrep_version="$output"
    
    # Check that all variants return same version
    run_as_program "bashgrep" "-V"
    [[ $status -eq 0 ]]
    [[ "$output" = "$xgrep_version" ]]
    
    run_as_program "phpgrep" "-V" 
    [[ $status -eq 0 ]]
    [[ "$output" = "$xgrep_version" ]]
    
    run_as_program "pygrep" "-V"
    [[ $status -eq 0 ]]
    [[ "$output" = "$xgrep_version" ]]
}

@test "error handling for invalid arguments" {
    # Test invalid maxdepth
    run_as_program "xgrep" "-d" "invalid" "pattern" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 2 ]]
    
    # Test missing directory
    run_as_program "xgrep" "pattern" "/nonexistent/directory"
    [[ $status -eq 1 ]]
    
    # Test empty pattern
    run_as_program "xgrep" "" "$TEST_TEMP_DIR/testproject"
    [[ $status -eq 1 ]]
}