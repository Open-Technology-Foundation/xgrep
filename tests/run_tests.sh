#!/bin/bash
# Test runner for xgrep test suite

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default options
RUN_UNIT=1
RUN_INTEGRATION=1
VERBOSE=0
PARALLEL=1

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run xgrep test suite

Options:
    -u, --unit-only        Run only unit tests
    -i, --integration-only Run only integration tests
    -v, --verbose          Verbose output
    -s, --sequential       Run tests sequentially (not in parallel)
    -h, --help            Show this help

Examples:
    $0                    # Run all tests
    $0 -u                 # Run only unit tests
    $0 -v                 # Run all tests with verbose output
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--unit-only)
            RUN_INTEGRATION=0
            shift
            ;;
        -i|--integration-only)
            RUN_UNIT=0
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -s|--sequential)
            PARALLEL=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Check dependencies
if ! command -v bats >/dev/null 2>&1; then
    echo "Error: BATS (Bash Automated Testing System) is required" >&2
    echo "Install with: sudo apt-get install bats (Debian/Ubuntu) or brew install bats (macOS)" >&2
    exit 1
fi

# Set up test environment
export BATS_TMPDIR="${TMPDIR:-/tmp}/xgrep-test-$$"
mkdir -p "$BATS_TMPDIR"
trap 'rm -rf "$BATS_TMPDIR"' EXIT

echo "=== xgrep Test Suite ==="
echo "Project directory: $PROJECT_DIR"
echo "Test directory: $SCRIPT_DIR"
echo "Temporary directory: $BATS_TMPDIR"
echo

# Set BATS options
BATS_OPTS=()
if [[ $VERBOSE -eq 1 ]]; then
    BATS_OPTS+=("--verbose")
fi

if [[ $PARALLEL -eq 1 ]]; then
    # Detect number of processors for parallel execution
    if command -v nproc >/dev/null 2>&1; then
        JOBS=$(nproc)
    else
        JOBS=4
    fi
    BATS_OPTS+=("--jobs" "$JOBS")
fi

# Run unit tests
if [[ $RUN_UNIT -eq 1 ]]; then
    echo "Running unit tests..."
    echo "===================="
    
    if ls "$SCRIPT_DIR"/unit/*.bats >/dev/null 2>&1; then
        if ! bats "${BATS_OPTS[@]}" "$SCRIPT_DIR"/unit/*.bats; then
            echo "Unit tests failed!" >&2
            exit 1
        fi
    else
        echo "No unit tests found in $SCRIPT_DIR/unit/"
    fi
    echo
fi

# Run integration tests
if [[ $RUN_INTEGRATION -eq 1 ]]; then
    echo "Running integration tests..."
    echo "============================"
    
    if ls "$SCRIPT_DIR"/integration/*.bats >/dev/null 2>&1; then
        if ! bats "${BATS_OPTS[@]}" "$SCRIPT_DIR"/integration/*.bats; then
            echo "Integration tests failed!" >&2
            exit 1
        fi
    else
        echo "No integration tests found in $SCRIPT_DIR/integration/"
    fi
    echo
fi

echo "All tests passed! ✓"