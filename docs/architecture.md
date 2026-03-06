# Architecture

Crystal port of the Go `x/exp/teatest/v2` library for testing Term2 programs. This library provides test helpers for Bubble Tea applications with golden file comparison support.

## Project Structure

```
teatest/
├── src/teatest.cr              # Main library implementation
├── spec/                       # Crystal specs
│   ├── teatest_spec.cr        # Main test suite
│   ├── app_spec.cr            # App testing specs
│   ├── send_spec.cr           # Send functionality specs
│   └── testdata/              # Golden test files
├── vendor/x/exp/teatest/v2/   # Upstream Go source (submodule)
│   ├── teatest.go             # Go implementation
│   ├── teatest_test.go        # Go tests
│   └── testdata/              # Go golden files
└── lib/                       # Crystal dependencies (shards)
```

## Data Flow

1. **Test Setup**: `Teatest.new_test_model` creates a test model wrapper
2. **Program Execution**: Term2 program runs in test mode with mocked I/O
3. **Output Capture**: Program output is captured to a buffer
4. **Assertion**: `Teatest.wait_for` or `Teatest.require_equal_output` validates output
5. **Cleanup**: `tm.quit` stops the test program

## Package/Module Responsibilities

- **`Teatest`**: Main test framework module
  - `TestModel`: Wrapper for Term2 models under test
  - `Program`: Test program interface
  - Golden file comparison utilities

- **`Term2`**: Bubble Tea framework (external dependency via `bubbletea.cr`)
  - Provides the Model/Update/View pattern for terminal applications

- **`Golden`**: Golden file testing (external dependency)
  - File comparison with diff output
  - Update mode for regenerating golden files

<!-- TODO: Add diagrams if helpful -->