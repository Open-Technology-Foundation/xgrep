#!/usr/bin/env bats
# Language-specific integration tests for xgrep tools

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    create_language_test_files
}

teardown() {
    teardown_test_env
}

create_language_test_files() {
    mkdir -p "$TEST_TEMP_DIR/multiproject"
    
    # Bash files with different extensions and shebangs
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/multiproject/script.sh"
    echo 'echo "bash_target_pattern"' >> "$TEST_TEMP_DIR/multiproject/script.sh"
    
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/multiproject/script.bash"
    echo 'echo "bash_target_pattern"' >> "$TEST_TEMP_DIR/multiproject/script.bash"
    
    echo 'echo "bash_target_pattern"' > "$TEST_TEMP_DIR/multiproject/bashfile_no_ext"
    echo '#!/bin/bash' | cat - "$TEST_TEMP_DIR/multiproject/bashfile_no_ext" > temp && mv temp "$TEST_TEMP_DIR/multiproject/bashfile_no_ext"
    
    # PHP files with different extensions and shebangs
    echo '<?php echo "php_target_pattern"; ?>' > "$TEST_TEMP_DIR/multiproject/index.php"
    echo '<p><?php echo "php_target_pattern"; ?></p>' > "$TEST_TEMP_DIR/multiproject/template.phtml"
    
    echo '#!/usr/bin/env php' > "$TEST_TEMP_DIR/multiproject/phpfile_no_ext"
    echo '<?php echo "php_target_pattern"; ?>' >> "$TEST_TEMP_DIR/multiproject/phpfile_no_ext"
    
    # Python files with different extensions and shebangs
    echo 'print("python_target_pattern")' > "$TEST_TEMP_DIR/multiproject/app.py"
    echo '# python_target_pattern in pyw' > "$TEST_TEMP_DIR/multiproject/script.pyw"
    
    echo '#!/usr/bin/env python3' > "$TEST_TEMP_DIR/multiproject/pyfile_no_ext"
    echo 'print("python_target_pattern")' >> "$TEST_TEMP_DIR/multiproject/pyfile_no_ext"
    
    # Make executable files executable
    chmod +x "$TEST_TEMP_DIR/multiproject/script.sh"
    chmod +x "$TEST_TEMP_DIR/multiproject/script.bash"
    chmod +x "$TEST_TEMP_DIR/multiproject/bashfile_no_ext"
    chmod +x "$TEST_TEMP_DIR/multiproject/phpfile_no_ext"
    chmod +x "$TEST_TEMP_DIR/multiproject/pyfile_no_ext"
}

# Test bashgrep language-specific functionality
@test "bashgrep finds all bash files regardless of extension" {
    run_as_program "bashgrep" "bash_target_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    
    # Should find .sh files
    [[ "$output" =~ "script.sh" ]]
    
    # Should find .bash files
    [[ "$output" =~ "script.bash" ]]
    
    # Should find bash files without extension (by shebang)
    [[ "$output" =~ "bashfile_no_ext" ]]
}

@test "bashgrep ignores non-bash files" {
    run_as_program "bashgrep" "target_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    
    # Should NOT find PHP files
    [[ ! "$output" =~ "index.php" ]]
    [[ ! "$output" =~ "template.phtml" ]]
    [[ ! "$output" =~ "phpfile_no_ext" ]]
    
    # Should NOT find Python files
    [[ ! "$output" =~ "app.py" ]]
    [[ ! "$output" =~ "script.pyw" ]]
    [[ ! "$output" =~ "pyfile_no_ext" ]]
}

# Test phpgrep language-specific functionality
@test "phpgrep finds all PHP files regardless of extension" {
    run_as_program "phpgrep" "php_target_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    
    # Should find .php files
    [[ "$output" =~ "index.php" ]]
    
    # Should find .phtml files
    [[ "$output" =~ "template.phtml" ]]
    
    # Should find PHP files without extension (by shebang)
    [[ "$output" =~ "phpfile_no_ext" ]]
}

@test "phpgrep ignores non-PHP files" {
    run_as_program "phpgrep" "target_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    
    # Should NOT find Bash files
    [[ ! "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "script.bash" ]]
    [[ ! "$output" =~ "bashfile_no_ext" ]]
    
    # Should NOT find Python files
    [[ ! "$output" =~ "app.py" ]]
    [[ ! "$output" =~ "script.pyw" ]]
    [[ ! "$output" =~ "pyfile_no_ext" ]]
}

# Test pygrep language-specific functionality
@test "pygrep finds all Python files regardless of extension" {
    run_as_program "pygrep" "python_target_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    
    # Should find .py files
    [[ "$output" =~ "app.py" ]]
    
    # Should find .pyw files
    [[ "$output" =~ "script.pyw" ]]
    
    # Should find Python files without extension (by shebang)
    [[ "$output" =~ "pyfile_no_ext" ]]
}

@test "pygrep ignores non-Python files" {
    run_as_program "pygrep" "target_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    
    # Should NOT find Bash files
    [[ ! "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "script.bash" ]]
    [[ ! "$output" =~ "bashfile_no_ext" ]]
    
    # Should NOT find PHP files
    [[ ! "$output" =~ "index.php" ]]
    [[ ! "$output" =~ "template.phtml" ]]
    [[ ! "$output" =~ "phpfile_no_ext" ]]
}

# Test cross-language pattern searches
@test "different language tools find same pattern in their respective files" {
    # Add the same pattern to files of different languages
    echo 'echo "common_pattern_test"' >> "$TEST_TEMP_DIR/multiproject/script.sh"
    echo 'echo "common_pattern_test";' >> "$TEST_TEMP_DIR/multiproject/index.php"
    echo 'print("common_pattern_test")' >> "$TEST_TEMP_DIR/multiproject/app.py"
    
    # Each tool should find the pattern only in its language files
    run_as_program "bashgrep" "common_pattern_test" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "index.php" ]]
    [[ ! "$output" =~ "app.py" ]]
    
    run_as_program "phpgrep" "common_pattern_test" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    [[ ! "$output" =~ "script.sh" ]]
    [[ "$output" =~ "index.php" ]]
    [[ ! "$output" =~ "app.py" ]]
    
    run_as_program "pygrep" "common_pattern_test" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    [[ ! "$output" =~ "script.sh" ]]
    [[ ! "$output" =~ "index.php" ]]
    [[ "$output" =~ "app.py" ]]
}

# Test shebang detection accuracy
@test "shebang detection works for edge cases" {
    # Test different shebang variations
    echo '#!/bin/sh' > "$TEST_TEMP_DIR/multiproject/sh_script"
    echo 'echo "sh_pattern"' >> "$TEST_TEMP_DIR/multiproject/sh_script"
    
    echo '#!/usr/bin/env python' > "$TEST_TEMP_DIR/multiproject/py2_script"
    echo 'print "py2_pattern"' >> "$TEST_TEMP_DIR/multiproject/py2_script"
    
    echo '#! /usr/bin/php' > "$TEST_TEMP_DIR/multiproject/php_spaced"
    echo '<?php echo "php_spaced_pattern"; ?>' >> "$TEST_TEMP_DIR/multiproject/php_spaced"
    
    chmod +x "$TEST_TEMP_DIR/multiproject/"*
    
    # bashgrep should find sh files
    run_as_program "bashgrep" "sh_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "sh_script" ]]
    
    # pygrep should find python2 files
    run_as_program "pygrep" "py2_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "py2_script" ]]
    
    # phpgrep should find PHP files with spaced shebang
    run_as_program "phpgrep" "php_spaced_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "php_spaced" ]]
}

# Test that xgrep finds patterns across all supported languages
@test "xgrep finds patterns in all supported language files" {
    echo 'echo "universal_pattern"' >> "$TEST_TEMP_DIR/multiproject/script.sh"
    echo 'echo "universal_pattern";' >> "$TEST_TEMP_DIR/multiproject/index.php"
    echo 'print("universal_pattern")' >> "$TEST_TEMP_DIR/multiproject/app.py"
    
    run_as_program "xgrep" "universal_pattern" "$TEST_TEMP_DIR/multiproject"
    [[ $status -eq 0 ]]
    
    # Should find in all language types
    [[ "$output" =~ "script.sh" ]]
    [[ "$output" =~ "index.php" ]]
    [[ "$output" =~ "app.py" ]]
}