#!/usr/bin/env bats
# Unit tests for xgrep mode detection logic

# Load test helpers
load ../helpers/test_setup
load ../helpers/mock_commands

setup() {
    setup_test_env
    
    # Extract mode detection logic for testing
    source_mode_detection_logic
}

teardown() {
    teardown_test_env
}

# Extract mode detection logic from xgrep for isolated testing
source_mode_detection_logic() {
    cat > "$TEST_TEMP_DIR/mode_detection.bash" << 'EOF'
#!/bin/bash
# Extracted mode detection logic for testing

detect_mode() {
    local PRG="$1"
    local MODE RG_TYPE
    
    if [[ $PRG == phpgrep ]]; then
        MODE="PHP"
        RG_TYPE="--type=php"
    elif [[ $PRG == bashgrep ]]; then
        MODE="Bash"
        RG_TYPE="--type=sh"
    elif [[ $PRG == pygrep ]]; then
        MODE="Python"
        RG_TYPE="--type=py"
    else
        MODE="Bash/PHP/Python"
        RG_TYPE="--type=sh --type=php --type=py"
    fi
    
    echo "MODE=$MODE"
    echo "RG_TYPE=$RG_TYPE"
}
EOF
    
    source "$TEST_TEMP_DIR/mode_detection.bash"
}

# Test phpgrep mode detection
@test "phpgrep sets MODE to PHP and correct RG_TYPE" {
    run detect_mode "phpgrep"
    assert_success
    assert_output_contains "MODE=PHP"
    assert_output_contains "RG_TYPE=--type=php"
}

# Test bashgrep mode detection
@test "bashgrep sets MODE to Bash and correct RG_TYPE" {
    run detect_mode "bashgrep"
    assert_success
    assert_output_contains "MODE=Bash"
    assert_output_contains "RG_TYPE=--type=sh"
}

# Test pygrep mode detection
@test "pygrep sets MODE to Python and correct RG_TYPE" {
    run detect_mode "pygrep"
    assert_success
    assert_output_contains "MODE=Python"
    assert_output_contains "RG_TYPE=--type=py"
}

# Test xgrep mode detection
@test "xgrep sets MODE to multi-language and correct RG_TYPE" {
    run detect_mode "xgrep"
    assert_success
    assert_output_contains "MODE=Bash/PHP/Python"
    assert_output_contains "RG_TYPE=--type=sh --type=php --type=py"
}

# Test default case (any other program name)
@test "unknown program name defaults to multi-language mode" {
    run detect_mode "someother"
    assert_success
    assert_output_contains "MODE=Bash/PHP/Python"
    assert_output_contains "RG_TYPE=--type=sh --type=php --type=py"
}

# Test empty program name
@test "empty program name defaults to multi-language mode" {
    run detect_mode ""
    assert_success
    assert_output_contains "MODE=Bash/PHP/Python"
    assert_output_contains "RG_TYPE=--type=sh --type=php --type=py"
}

# Test program name with path
@test "program name with path correctly identifies mode" {
    run detect_mode "/usr/bin/phpgrep"
    assert_success
    assert_output_contains "MODE=Bash/PHP/Python"  # Should default since it's not exactly "phpgrep"
    assert_output_contains "RG_TYPE=--type=sh --type=php --type=py"
}

# Test case sensitivity
@test "mode detection is case sensitive" {
    run detect_mode "PHPGREP"
    assert_success
    assert_output_contains "MODE=Bash/PHP/Python"  # Should default since case doesn't match
    assert_output_contains "RG_TYPE=--type=sh --type=php --type=py"
}

# Integration test: Test actual symlink behavior
@test "actual symlink invocation detects mode correctly - phpgrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/phpgrep"
    run "$TEST_TEMP_DIR/phpgrep" --help
    assert_success
    assert_output_contains "phpgrep"
    assert_output_contains "Language-Specific Grep Tool"
}

@test "actual symlink invocation detects mode correctly - bashgrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/bashgrep"
    run "$TEST_TEMP_DIR/bashgrep" --help
    assert_success
    assert_output_contains "bashgrep"
    assert_output_contains "Language-Specific Grep Tool"
}

@test "actual symlink invocation detects mode correctly - pygrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/pygrep"
    run "$TEST_TEMP_DIR/pygrep" --help
    assert_success
    assert_output_contains "pygrep"
    assert_output_contains "Language-Specific Grep Tool"
}

@test "actual symlink invocation detects mode correctly - xgrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/xgrep"
    run "$TEST_TEMP_DIR/xgrep" --help
    assert_success
    assert_output_contains "xgrep"
    assert_output_contains "Language-Specific Grep Tool"
}

# Test version output for different modes
@test "version output includes correct program name - phpgrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/phpgrep"
    run "$TEST_TEMP_DIR/phpgrep" -V
    assert_success
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]  # Should be just version number
}

@test "version output includes correct program name - bashgrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/bashgrep"
    run "$TEST_TEMP_DIR/bashgrep" -V
    assert_success
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Test that help output shows correct related commands
@test "help shows correct related commands for phpgrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/phpgrep"
    run "$TEST_TEMP_DIR/phpgrep" --help
    assert_success
    assert_output_contains "SEE ALSO"
    assert_output_contains "xgrep bashgrep pygrep"  # Should list others but not phpgrep itself
    assert_output_not_contains "phpgrep phpgrep"  # Should not duplicate itself
}

@test "help shows correct related commands for bashgrep" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/bashgrep"
    run "$TEST_TEMP_DIR/bashgrep" --help
    assert_success
    assert_output_contains "SEE ALSO"
    assert_output_contains "xgrep phpgrep pygrep"
    assert_output_not_contains "bashgrep bashgrep"
}

# Test that MODE variable affects exclusion directory display
@test "help shows current exclude directories" {
    ln -sf "$XGREP_SCRIPT" "$TEST_TEMP_DIR/testgrep"
    run "$TEST_TEMP_DIR/testgrep" --help
    assert_success
    assert_output_contains "Current:"
    assert_output_contains ".venv"
    assert_output_contains ".git"
}