# Development

## Prerequisites

- **Crystal** >= 1.19.1
- **Git** with submodule support
- **Go** (optional, for upstream verification)
- **Ruby** and **Python 3** (for the parity inventory gate)

## Setup

1. Clone the repository with submodules:
   ```bash
   git clone --recurse-submodules https://github.com/dsisnero/teatest.git
   cd teatest
   ```

2. Install Crystal dependencies:
   ```bash
   make install
   ```

3. Verify upstream Go source is available:
   ```bash
   ls vendor/x/exp/teatest/v2/teatest.go
   ```

## Daily Workflow

1. **Resume**: read [plans/parity.md](../plans/parity.md) → **Where we are**,
   then follow [docs/resuming.md](resuming.md).

2. **Start development session**:
   ```bash
   make install    # Ensure dependencies
   ```

3. **Run tests** (after changes):
   ```bash
   make test       # Run all specs
   ```

4. **Check code quality**:
   ```bash
   make format     # Check formatting
   make lint       # Run linter
   make inventory  # Check parity ledger drift
   ```

5. **Verify upstream parity** (for porting work):
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
| `make inventory` | Check the parity ledger against the pinned vendor tree |
| `make parity-refresh` | Regenerate source/test manifests (upstream bump only) |
| `make clean` | Strip AppleDouble sidecars, clear `./temp/*` |

### Additional Useful Commands

- **Run specific test file**: `crystal spec spec/teatest_spec.cr`
- **Regenerate golden files**: `GOLDEN_UPDATE=1 crystal spec`
- **Check upstream Go tests**: `cd vendor/x/exp/teatest && go test ./v2 -v`
- **Strict parity preflight**: `"$PARITY_SKILL_DIR/scripts/verify_skill_install.sh" . go regex`

## Project Structure and Porting Notes

- `src/teatest.cr` — the whole library; mirrors `vendor/x/exp/teatest/v2/teatest.go`.
- `spec/` — Crystal specs translated from the upstream Go tests; golden files
  live in `spec/testdata/`.
- `vendor/x` — the `charmbracelet/x` submodule. Only `exp/teatest/v2` is the
  source of truth; `exp/teatest/*.go` is the older v1 code.
- `plans/parity.md` — curated feature roadmap and current state.
- `plans/inventory/` — parity ledger plus generated source/test manifests.
- `scripts/` — forwarding wrappers for the installed parity skill; do not add
  copied skill implementations here.

## Environment Notes

This checkout lives on an external volume where macOS writes AppleDouble `._*`
sidecars next to edited files. `make format`, `make lint`, and `make test`
depend on the `sidecars` target, which deletes them first. See
[resuming.md](resuming.md#environment-notes) for the git-pack workaround.
