#!/usr/bin/env bash

# Test runner for imp-spawner.sh
# Runs all test cases and compares output with expected results

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_file="$1"
    local expected_file="$2"
    local test_name="$3"
    
    echo -e "${BLUE}Running test: $test_name${NC}"
    
    # Run the spawner on the test file
    local output_file="/tmp/imp-test-output-$$"
    ../imp-spawner.sh "$test_file" > "$output_file" 2>&1
    
    # Compare with expected output
    if diff -w "$expected_file" "$output_file" > /dev/null; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Expected:"
        cat "$expected_file"
        echo ""
        echo "Actual:"
        cat "$output_file"
        echo ""
        echo "Diff:"
        diff -w "$expected_file" "$output_file" || true
        echo ""
        ((FAILED++))
    fi
    
    rm -f "$output_file"
}

# Main test execution
main() {
    echo "Running IMP Spawner Test Suite"
    echo "=============================="
    echo ""
    
    # Run all tests
    run_test "test-1-simple-linear.md" "expected-1-simple-linear.txt" "Simple Linear Dependencies"
    run_test "test-2-parallel-phases.md" "expected-2-parallel-phases.txt" "Parallel Phases"
    run_test "test-3-mixed-statuses.md" "expected-3-mixed-statuses.txt" "Mixed Statuses"
    run_test "test-4-complex-dependencies.md" "expected-4-complex-dependencies.txt" "Complex Dependencies"
    run_test "test-5-edge-cases.md" "expected-5-edge-cases.txt" "Edge Cases"
    run_test "test-6-failed-status.md" "expected-6-failed-status.txt" "Failed Status"
    
    echo ""
    echo "=============================="
    echo "Test Results:"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main "$@" 