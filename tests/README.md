# IMP Spawner Test Suite

This directory contains comprehensive tests for the `imp-spawner.sh` script to ensure it correctly parses Mermaid diagrams and identifies eligible phases.

## Test Cases

### 1. Simple Linear Dependencies (`test-1-simple-linear.md`)
- **Scenario**: 3 phases in a simple linear sequence
- **Tests**: Basic dependency parsing and eligibility detection
- **Expected**: Only Phase1 should be eligible (no dependencies)

### 2. Parallel Phases (`test-2-parallel-phases.md`)
- **Scenario**: Multiple phases that can run in parallel after a common dependency
- **Tests**: Parallel dependency handling
- **Expected**: Only Phase1 should be eligible initially

### 3. Mixed Statuses (`test-3-mixed-statuses.md`)
- **Scenario**: Phases with different statuses (complete, inProgress, incomplete)
- **Tests**: Status-based filtering and dependency resolution
- **Expected**: Phase3 should be eligible (Phase1 is complete, Phase2 is inProgress)

### 4. Complex Dependencies (`test-4-complex-dependencies.md`)
- **Scenario**: Complex dependency graph with multiple paths and convergence
- **Tests**: Complex dependency resolution
- **Expected**: Only Phase1 should be eligible initially

### 5. Edge Cases (`test-5-edge-cases.md`)
- **Scenario**: Phases without labels, missing statuses, unusual formatting
- **Tests**: Robust parsing of edge cases
- **Expected**: Only Phase1 should be eligible initially

### 6. Failed Status (`test-6-failed-status.md`)
- **Scenario**: Phases with failed status and alternative paths
- **Tests**: Failed status handling and alternative dependency paths
- **Expected**: Phase3 should be eligible (Phase1 is complete, Phase2 is failed)

## Running Tests

```bash
cd tests
./run-tests.sh
```

## Test Structure

Each test consists of:
- **Test file**: `test-X-description.md` - Mermaid diagram to test
- **Expected output**: `expected-X-description.txt` - Expected spawner output
- **Test runner**: `run-tests.sh` - Executes all tests and compares results

## Adding New Tests

1. Create a new test file: `test-X-description.md`
2. Create expected output: `expected-X-description.txt`
3. Add the test to `run-tests.sh` in the main() function
4. Run the test suite to verify

## Test Coverage

The test suite covers:
- ✅ Basic dependency parsing
- ✅ Phase status detection
- ✅ Eligibility logic
- ✅ Edge cases (missing labels, statuses)
- ✅ Complex dependency graphs
- ✅ Parallel phase detection
- ✅ Status-based filtering 