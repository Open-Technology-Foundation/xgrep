# Makefile for xgrep project
# Provides convenient targets for testing, linting, and development

.PHONY: help test test-unit test-integration test-verbose \
        clean lint install uninstall install-user uninstall-user \
        check-deps test-summary

# Default target
help:
	@echo "xgrep - Advanced Language-Specific Grep Tool"
	@echo ""
	@echo "Available targets:"
	@echo "  help              Show this help message"
	@echo "  test              Run all tests (unit + integration)"
	@echo "  test-unit         Run only unit tests"
	@echo "  test-integration  Run only integration tests"
	@echo "  test-verbose      Run all tests with verbose output"
	@echo "  lint              Run shellcheck on main script"
	@echo "  clean             Clean up test artifacts"
	@echo "  check-deps        Check development dependencies"
	@echo "  test-summary      Show test coverage summary"
	@echo ""
	@echo "Installation (requires sudo):"
	@echo "  install           Install to /usr/local/bin"
	@echo "  uninstall         Remove from /usr/local/bin"
	@echo ""
	@echo "User Installation (no sudo required):"
	@echo "  install-user      Install to ~/.local/bin"
	@echo "  uninstall-user    Remove from ~/.local/bin"
	@echo ""
	@echo "Requirements:"
	@echo "  - bats (for testing)"
	@echo "  - shellcheck (for linting)"
	@echo "  - ripgrep (recommended for performance)"

# Test targets
test:
	@echo "Running all xgrep tests..."
	./tests/run_tests.sh

test-unit:
	@echo "Running unit tests..."
	./tests/run_tests.sh --unit-only

test-integration:
	@echo "Running integration tests..."
	./tests/run_tests.sh --integration-only

test-verbose:
	@echo "Running all tests with verbose output..."
	./tests/run_tests.sh --verbose

# Development targets
lint:
	@echo "Running shellcheck on xgrep script..."
	shellcheck xgrep
	@echo "Shellcheck passed!"

clean:
	@echo "Cleaning up test artifacts..."
	rm -rf tests/tmp
	rm -f test_*.tmp
	rm -f manual_test.sh testfile.sh
	rm -rf testbuild test_manual
	@echo "Clean complete!"

# System-wide installation (requires sudo)
install:
	@echo "Installing xgrep to /usr/local/bin (requires sudo)..."
	sudo ln -sf "$(PWD)/xgrep" /usr/local/bin/xgrep
	sudo ln -sf "$(PWD)/xgrep" /usr/local/bin/bashgrep
	sudo ln -sf "$(PWD)/xgrep" /usr/local/bin/phpgrep
	sudo ln -sf "$(PWD)/xgrep" /usr/local/bin/pygrep
	@echo "Installation complete!"
	@echo "Commands available: xgrep, bashgrep, phpgrep, pygrep"

uninstall:
	@echo "Removing xgrep from /usr/local/bin (requires sudo)..."
	sudo rm -f /usr/local/bin/xgrep
	sudo rm -f /usr/local/bin/bashgrep
	sudo rm -f /usr/local/bin/phpgrep
	sudo rm -f /usr/local/bin/pygrep
	@echo "Uninstall complete!"

# User-local installation (no sudo required)
install-user:
	@echo "Installing xgrep to ~/.local/bin..."
	@mkdir -p ~/.local/bin
	ln -sf "$(PWD)/xgrep" ~/.local/bin/xgrep
	ln -sf "$(PWD)/xgrep" ~/.local/bin/bashgrep
	ln -sf "$(PWD)/xgrep" ~/.local/bin/phpgrep
	ln -sf "$(PWD)/xgrep" ~/.local/bin/pygrep
	@echo "Installation complete!"
	@echo "Ensure ~/.local/bin is in your PATH"

uninstall-user:
	@echo "Removing xgrep from ~/.local/bin..."
	rm -f ~/.local/bin/xgrep
	rm -f ~/.local/bin/bashgrep
	rm -f ~/.local/bin/phpgrep
	rm -f ~/.local/bin/pygrep
	@echo "Uninstall complete!"

# Development dependencies check
check-deps:
	@echo "Checking dependencies..."
	@command -v bats >/dev/null 2>&1 || (echo "ERROR: bats is required for testing" && exit 1)
	@command -v shellcheck >/dev/null 2>&1 || (echo "WARNING: shellcheck recommended for linting")
	@command -v rg >/dev/null 2>&1 || command -v ripgrep >/dev/null 2>&1 || (echo "WARNING: ripgrep recommended for performance")
	@echo "Dependencies OK!"

# Test coverage summary (manual)
test-summary:
	@echo "Test Summary:"
	@echo "============="
	@echo "Unit Tests:"
	@echo "  ✓ Helper functions (error, die, noarg, xcleanup)"
	@echo "  ✓ Mode detection (program name → language mapping)"
	@echo "  ✓ Argument parsing (options, validation, errors)"
	@echo "  ⚠ Fallback logic (limited due to PATH mocking issues)"
	@echo ""
	@echo "Integration Tests:"
	@echo "  ✓ Basic functionality (pattern search, file type filtering)"
	@echo "  ✓ Language-specific tools (bashgrep, phpgrep, pygrep)"
	@echo "  ⚠ Some edge cases with shebang detection"
	@echo ""
	@echo "Known Issues to Address:"
	@echo "  - Exit code handling for 'no matches' case"
	@echo "  - Fallback mode testing needs PATH isolation improvement"
	@echo "  - Shebang detection might be limited by ripgrep's built-in types"
