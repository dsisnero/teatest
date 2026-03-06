# Development

## Prerequisites

- **Crystal** >= 1.19.1
- **Git** with submodule support
- **Go** (optional, for upstream verification)

## Setup

1. Clone the repository with submodules:
   ```bash
   git clone --recurse-submodules https://github.com/dsisnero/teatest.git
   cd teatest
   ```

2. Install Crystal dependencies:
   ```bash
   make install
   # or
   BEADS_DIR=$(pwd)/.beads shards install
   ```

3. Verify upstream Go source is available:
   ```bash
   ls vendor/x/exp/teatest/v2/teatest.go
   ```

## Daily Workflow

1. **Start development session**:
   ```bash
   make install    # Ensure dependencies
   ```

2. **Run tests** (after changes):
   ```bash
   make test       # Run all specs
   ```

3. **Check code quality**:
   ```bash
   make format     # Check formatting
   make lint       # Run linter
   ```

4. **Verify upstream parity** (for porting work):
   ```bash
   cd vendor/x/exp/teatest && go test ./v2
   ```

## Available Commands

| Command | Description |
|---------|-------------|
| `make install` | Install Crystal dependencies |
| `make update` | Update Crystal dependencies |
| `make format` | Check code formatting |
| `make lint` | Run linter (ameba) |
| `make test` | Run all specs |
| `make clean` | Clean temporary files |

### Additional Useful Commands

- **Run specific test file**: `crystal spec spec/teatest_spec.cr`
- **Run with update flag**: `crystal spec -Dpreview_mt -Dexecution_context --update`
- **Check upstream Go tests**: `cd vendor/x/exp/teatest && go test ./v2 -v`