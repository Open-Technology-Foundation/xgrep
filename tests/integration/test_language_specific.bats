#!/usr/bin/env bats
# Language-specific integration tests for xgrep tools

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    create_language_test_files
    create_edge_case_files
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

create_edge_case_files() {
    mkdir -p "$TEST_TEMP_DIR/edgecases"

    # Extension vs shebang conflicts
    printf '#!/bin/bash\necho "EDGE_BASH_TXT"\n' > "$TEST_TEMP_DIR/edgecases/wrong_ext.txt"
    printf '#!/usr/bin/env python3\nprint("EDGE_PY_SH")\n' > "$TEST_TEMP_DIR/edgecases/python_in.sh"
    printf '#!/usr/bin/env php\n<?php echo "EDGE_PHP_PY"; ?>\n' > "$TEST_TEMP_DIR/edgecases/php_in.py"

    # Extension-only files (no shebang)
    printf 'echo "EDGE_BASH_NOSHEBANG"\n' > "$TEST_TEMP_DIR/edgecases/no_shebang.sh"
    printf 'print("EDGE_PY_NOSHEBANG")\n' > "$TEST_TEMP_DIR/edgecases/no_shebang.py"
    printf '<?php echo "EDGE_PHP_NOSHEBANG"; ?>\n' > "$TEST_TEMP_DIR/edgecases/no_shebang.php"

    # Alternative shebang paths
    printf '#!/usr/bin/python3\nprint("EDGE_USRBIN_PY")\n' > "$TEST_TEMP_DIR/edgecases/usrbin_python"
    printf '#!/usr/local/bin/python3\nprint("EDGE_LOCAL_PY")\n' > "$TEST_TEMP_DIR/edgecases/local_python"
    printf '#!/usr/bin/bash\necho "EDGE_USRBIN_BASH"\n' > "$TEST_TEMP_DIR/edgecases/usrbin_bash"

    # Multi-dot filenames
    printf '#!/bin/bash\necho "EDGE_MULTIDOT"\n' > "$TEST_TEMP_DIR/edgecases/script.test.sh"

    # Control file (should NEVER match any language tool)
    printf 'EDGE_CONTROL_TEXT plain text\n' > "$TEST_TEMP_DIR/edgecases/readme.txt"

    chmod +x "$TEST_TEMP_DIR/edgecases"/*
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

# ============================================
# Edge Case Tests - Extension vs Shebang
# ============================================

@test "edge: bashgrep finds .txt file with bash shebang" {
    run_as_program "bashgrep" "EDGE_BASH_TXT" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "wrong_ext.txt" ]]
}

@test "edge: bashgrep finds .sh file regardless of python shebang" {
    run_as_program "bashgrep" "EDGE_PY_SH" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "python_in.sh" ]]
}

@test "edge: pygrep ignores .sh file even with python shebang" {
    run_as_program "pygrep" "EDGE_PY_SH" "$TEST_TEMP_DIR/edgecases"
    [[ ! "$output" =~ "python_in.sh" ]]
}

@test "edge: pygrep finds .py file regardless of php shebang" {
    run_as_program "pygrep" "EDGE_PHP_PY" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "php_in.py" ]]
}

@test "edge: phpgrep ignores .py file even with php shebang" {
    run_as_program "phpgrep" "EDGE_PHP_PY" "$TEST_TEMP_DIR/edgecases"
    [[ ! "$output" =~ "php_in.py" ]]
}

# ============================================
# Edge Case Tests - Extension Only (No Shebang)
# ============================================

@test "edge: bashgrep finds .sh file without shebang" {
    run_as_program "bashgrep" "EDGE_BASH_NOSHEBANG" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "no_shebang.sh" ]]
}

@test "edge: pygrep finds .py file without shebang" {
    run_as_program "pygrep" "EDGE_PY_NOSHEBANG" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "no_shebang.py" ]]
}

@test "edge: phpgrep finds .php file without shebang" {
    run_as_program "phpgrep" "EDGE_PHP_NOSHEBANG" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "no_shebang.php" ]]
}

# ============================================
# Edge Case Tests - Alternative Shebang Paths
# ============================================

@test "edge: pygrep finds file with /usr/bin/python3 shebang" {
    run_as_program "pygrep" "EDGE_USRBIN_PY" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "usrbin_python" ]]
}

@test "edge: pygrep finds file with /usr/local/bin/python3 shebang" {
    run_as_program "pygrep" "EDGE_LOCAL_PY" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "local_python" ]]
}

@test "edge: bashgrep finds file with /usr/bin/bash shebang" {
    run_as_program "bashgrep" "EDGE_USRBIN_BASH" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "usrbin_bash" ]]
}

# ============================================
# Edge Case Tests - Multi-dot Filenames
# ============================================

@test "edge: bashgrep finds multi.dot.script.sh" {
    run_as_program "bashgrep" "EDGE_MULTIDOT" "$TEST_TEMP_DIR/edgecases"
    [[ $status -eq 0 ]]
    [[ "$output" =~ "script.test.sh" ]]
}

# ============================================
# Edge Case Tests - Control (Plain Text)
# ============================================

@test "edge: bashgrep ignores plain .txt file without shebang" {
    run_as_program "bashgrep" "EDGE_CONTROL_TEXT" "$TEST_TEMP_DIR/edgecases"
    [[ ! "$output" =~ "readme.txt" ]]
}

@test "edge: phpgrep ignores plain .txt file" {
    run_as_program "phpgrep" "EDGE_CONTROL_TEXT" "$TEST_TEMP_DIR/edgecases"
    [[ ! "$output" =~ "readme.txt" ]]
}

@test "edge: pygrep ignores plain .txt file" {
    run_as_program "pygrep" "EDGE_CONTROL_TEXT" "$TEST_TEMP_DIR/edgecases"
    [[ ! "$output" =~ "readme.txt" ]]
}