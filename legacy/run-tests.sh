#!/bin/bash

echo "Running Phase Analyzer Test Suite"
echo "================================="
echo

for test_file in tests/test-spec-*.mdx; do
    echo "Testing: $(basename "$test_file")"
    echo "Expected:"
    case "$(basename "$test_file")" in
        "test-spec-basic.mdx")
            echo "  Phase 1: Setup"
            ;;
        "test-spec-parallel.mdx")
            echo "  Phase 2a: Alpha, Phase 2b: Beta, Phase 2c: Gamma"
            ;;
        "test-spec-gaps.mdx")
            echo "  Phase 1: Start"
            ;;
        "test-spec-duplicates.mdx")
            echo "  Phase 1: Duplicate (first occurrence)"
            ;;
        "test-spec-malformed.mdx")
            echo "  Phase 2: Good (only properly formatted phase)"
            ;;
        "test-spec-complete.mdx")
            echo "  All phases complete"
            ;;
        "test-spec-mixed.mdx")
            echo "  Phase 2a: Incomplete, Phase 2b: Complete, Phase 3: Incomplete"
            ;;
    esac
    echo "Actual:"
    echo "  $(./phase-analyzer.sh "$test_file")"
    echo
done 