# Makefile for xgrep project
# Provides convenient targets for testing, linting, and development

.PHONY: help test test-unit test-integration test-verbose \
        clean lint install uninstall install-user uninstall-user \
        check-deps test-summary

# Installation directories
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man/man1
COMPDIR = /etc/bash_completion.d

# User installation directories
USER_BINDIR = $(HOME)/.local/bin
USER_MANDIR = $(HOME)/.local/share/man/man1
USER_COMPDIR = $(HOME)/.local/share/bash-completion/completions

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
	@echo "  install           Install to $(BINDIR) with manpage and completions"
	@echo "  uninstall         Remove from $(BINDIR)"
	@echo ""
	@echo "User Installation (no sudo required):"
	@echo "  install-user      Install to ~/.local/bin with manpage and completions"
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
	@echo "Installing xgrep to $(BINDIR) (requires sudo)..."
	sudo mkdir -p $(BINDIR) $(MANDIR) $(COMPDIR)
	sudo ln -sf "$(PWD)/xgrep" $(BINDIR)/xgrep
	sudo ln -sf "$(PWD)/xgrep" $(BINDIR)/bashgrep
	sudo ln -sf "$(PWD)/xgrep" $(BINDIR)/phpgrep
	sudo ln -sf "$(PWD)/xgrep" $(BINDIR)/pygrep
	@echo "Installing manpage to $(MANDIR)..."
	sudo install -m 644 xgrep.1 $(MANDIR)/xgrep.1
	sudo ln -sf xgrep.1 $(MANDIR)/bashgrep.1
	sudo ln -sf xgrep.1 $(MANDIR)/phpgrep.1
	sudo ln -sf xgrep.1 $(MANDIR)/pygrep.1
	@echo "Installing bash completion to $(COMPDIR)..."
	sudo install -m 644 xgrep.bash_completion $(COMPDIR)/xgrep
	@echo "Installation complete!"
	@echo "Commands available: xgrep, bashgrep, phpgrep, pygrep"
	@echo "Run 'man bashgrep' or 'man xgrep' for documentation"

uninstall:
	@echo "Removing xgrep from $(BINDIR) (requires sudo)..."
	sudo rm -f $(BINDIR)/xgrep $(BINDIR)/bashgrep $(BINDIR)/phpgrep $(BINDIR)/pygrep
	@echo "Removing manpages from $(MANDIR)..."
	sudo rm -f $(MANDIR)/xgrep.1 $(MANDIR)/bashgrep.1 $(MANDIR)/phpgrep.1 $(MANDIR)/pygrep.1
	@echo "Removing bash completion from $(COMPDIR)..."
	sudo rm -f $(COMPDIR)/xgrep
	@echo "Uninstall complete!"

# User-local installation (no sudo required)
install-user:
	@echo "Installing xgrep to $(USER_BINDIR)..."
	@mkdir -p $(USER_BINDIR) $(USER_MANDIR) $(USER_COMPDIR)
	ln -sf "$(PWD)/xgrep" $(USER_BINDIR)/xgrep
	ln -sf "$(PWD)/xgrep" $(USER_BINDIR)/bashgrep
	ln -sf "$(PWD)/xgrep" $(USER_BINDIR)/phpgrep
	ln -sf "$(PWD)/xgrep" $(USER_BINDIR)/pygrep
	@echo "Installing manpage to $(USER_MANDIR)..."
	install -m 644 xgrep.1 $(USER_MANDIR)/xgrep.1
	ln -sf xgrep.1 $(USER_MANDIR)/bashgrep.1
	ln -sf xgrep.1 $(USER_MANDIR)/phpgrep.1
	ln -sf xgrep.1 $(USER_MANDIR)/pygrep.1
	@echo "Installing bash completion to $(USER_COMPDIR)..."
	install -m 644 xgrep.bash_completion $(USER_COMPDIR)/xgrep
	@echo "Installation complete!"
	@echo "Ensure ~/.local/bin is in your PATH"
	@echo "Run 'man bashgrep' or 'man xgrep' for documentation"
	@echo "Note: You may need to add ~/.local/share/man to MANPATH"

uninstall-user:
	@echo "Removing xgrep from $(USER_BINDIR)..."
	rm -f $(USER_BINDIR)/xgrep $(USER_BINDIR)/bashgrep $(USER_BINDIR)/phpgrep $(USER_BINDIR)/pygrep
	@echo "Removing manpages from $(USER_MANDIR)..."
	rm -f $(USER_MANDIR)/xgrep.1 $(USER_MANDIR)/bashgrep.1 $(USER_MANDIR)/phpgrep.1 $(USER_MANDIR)/pygrep.1
	@echo "Removing bash completion from $(USER_COMPDIR)..."
	rm -f $(USER_COMPDIR)/xgrep
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
