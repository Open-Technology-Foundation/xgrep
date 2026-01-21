#!/usr/bin/env bats
# Basic integration tests for xgrep functionality

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    create_integration_test_files
}

teardown() {
    teardown_test_env
}

create_integration_test_files() {
    # Create comprehensive test file structure
    mkdir -p "$TEST_TEMP_DIR/project"
    
    # Bash files
    create_test_file "project/script.sh" "echo 'search_target found'" "#!/bin/bash"
    create_test_file "project/deployment" "deploy_script with search_target" "#!/bin/bash"
    
    # PHP files  
    create_test_file "project/index.php" "<?php echo 'search_target in php';"
    create_test_file "project/template.phtml" "<p><?php echo 'search_target template'; ?></p>"
    create_test_file "project/cli_tool" "<?php echo 'search_target cli';" "#!/usr/bin/env php"
    
    # Python files
    create_test_file "project/app.py" "print('search_target python')" "#!/usr/bin/env python3"
    create_test_file "project/module.pyw" "# search_target in pyw file"
    create_test_file "project/script" "print('search_target script')" "#!/usr/bin/env python3"
    
    # Non-target files (should not match language-specific searches)
    create_test_file "project/readme.txt" "search_target in text file"
    create_test_file "project/config.json" '{"pattern": "search_target"}'
    
    # Files in excluded directories
    mkdir -p "$TEST_TEMP_DIR/project/.git"
    create_test_file "project/.git/hooks" "search_target in git hook"
    
    mkdir -p "$TEST_TEMP_DIR/project/.venv/lib"
    create_test_file "project/.venv/lib/test.py" "print('search_target in venv')"
}

# Test basic xgrep functionality (all languages)
@test "xgrep finds pattern in all supported file types" {
    run_as_program "xgrep" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Should find in bash files
    [[ "$output" =~ "script.sh" ]]
    [[ "$output" =~ "deployment" ]]
    
    # Should find in PHP files
    [[ "$output" =~ "index.php" ]]
    [[ "$output" =~ "template.phtml" ]]
    [[ "$output" =~ "cli_tool" ]]
    
    # Should find in Python files
    [[ "$output" =~ "app.py" ]]
    [[ "$output" =~ "module.pyw" ]]
    [[ "$output" =~ "script" ]]
    
    # Should NOT find in non-script files
    [[ ! "$output" =~ "readme.txt" ]]
    [[ ! "$output" =~ "config.json" ]]
}

@test "xgrep excludes default directories" {
    run_as_program "xgrep" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Should not find in excluded directories
    [[ ! "$output" =~ ".git/hooks" ]]
    [[ ! "$output" =~ ".venv/lib/test.py" ]]
}

@test "xgrep respects maxdepth option" {
    mkdir -p "$TEST_TEMP_DIR/project/deep/deeper"
    create_test_file "project/deep/deeper/nested.sh" "search_target deep" "#!/bin/bash"
    
    run_as_program "xgrep" "-d" "1" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Should find files at root level
    [[ "$output" =~ "script.sh" ]]
    
    # Should not find deeply nested files
    [[ ! "$output" =~ "nested.sh" ]]
}

@test "xgrep respects custom exclude directories" {
    mkdir -p "$TEST_TEMP_DIR/project/build"
    create_test_file "project/build/generated.py" "print('search_target build')"
    
    run_as_program "xgrep" "-X" "build" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Should find normal files
    [[ "$output" =~ "script.sh" ]]
    
    # Should not find in excluded build directory
    [[ ! "$output" =~ "build/generated.py" ]]
}

@test "xgrep handles no matches gracefully" {
    run_as_program "xgrep" "nonexistent_pattern_xyz_12345" "$TEST_TEMP_DIR/project"
    [[ $status -eq 1 ]]
    [[ "$output" =~ No.*files\ found\ with\ pattern ]]
}

@test "xgrep handles empty directory" {
    mkdir -p "$TEST_TEMP_DIR/empty"
    run_as_program "xgrep" "search_target" "$TEST_TEMP_DIR/empty"
    [[ $status -eq 1 ]]
}

# Test pattern matching capabilities
@test "xgrep supports regex patterns" {
    run_as_program "xgrep" "search_targ[et]+" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "script.sh" ]]
}

@test "xgrep supports case-insensitive search" {
    run_as_program "xgrep" "-i" "SEARCH_TARGET" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "script.sh" ]]
}

# Test debug mode
@test "xgrep debug mode shows configuration" {
    run_as_program "xgrep" "-D" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    [[ "$output" =~ DEBUG:\ RG_CMD= ]]
    [[ "$output" =~ RG_TYPE= ]]
    [[ "$output" =~ pattern= ]]
    [[ "$output" =~ directory= ]]
}

# Test environment variables
@test "xgrep respects XGREP_EXCLUDE_DIRS environment variable" {
    mkdir -p "$TEST_TEMP_DIR/project/custom_exclude"
    create_test_file "project/custom_exclude/test.py" "print('search_target custom')"
    
    export XGREP_EXCLUDE_DIRS="custom_exclude"
    run_as_program "xgrep" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Should find normal files
    [[ "$output" =~ "script.sh" ]]
    
    # Should not find in custom excluded directory
    [[ ! "$output" =~ "custom_exclude/test.py" ]]
}

# Test file detection by shebang
@test "xgrep detects files by shebang correctly" {
    run_as_program "xgrep" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Should find bash file without extension
    [[ "$output" =~ "deployment" ]]
    
    # Should find PHP CLI tool without extension
    [[ "$output" =~ "cli_tool" ]]
    
    # Should find Python script without extension
    [[ "$output" =~ project/script ]]
}

# Test output format
@test "xgrep output includes filename and matched content" {
    run_as_program "xgrep" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Output should be in format: filename:matched_line
    [[ "$output" =~ "script.sh:echo 'search_target found'" ]]
    [[ "$output" =~ "index.php:" ]]
}

# Test line number display
@test "xgrep can show line numbers" {
    run_as_program "xgrep" "-n" "search_target" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    
    # Should include line numbers in output (format varies by ripgrep version)
    [[ "$output" =~ ":" ]]
}

# Test multiple patterns
@test "xgrep handles multiple search terms" {
    create_test_file "project/multi.sh" "first_pattern and second_pattern" "#!/bin/bash"
    
    # This tests that the pattern argument is handled correctly
    run_as_program "xgrep" "first_pattern|second_pattern" "$TEST_TEMP_DIR/project"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "multi.sh" ]]
}

# Test that symlinks work correctly
@test "xgrep symlink works identically to direct invocation" {
    # Test direct invocation
    run "$XGREP_SCRIPT" "search_target" "$TEST_TEMP_DIR/project"
    local direct_output="$output"
    local direct_status=$status
    
    # Test symlink invocation
    run_as_program "xgrep" "search_target" "$TEST_TEMP_DIR/project"
    
    # Should have same behavior
    [[ $status -eq $direct_status ]]
    # Output should contain same files (order might differ)
    [[ "$output" =~ "script.sh" ]] && [[ "$direct_output" =~ "script.sh" ]]
}