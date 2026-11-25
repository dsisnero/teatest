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

## Continuous Integration

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs the four gates on
every push to `main` and every pull request:

| Step | Command | Notes |
|------|---------|-------|
| Checkout | `actions/checkout` with `submodules: recursive` | `vendor/x` is the upstream submodule |
| Install Crystal | `crystal-lang/install-crystal` | pinned to the compiler that accepted the fixtures (1.22.3) |
| Install shards | `shards install` | `bubbletea` tracks `main`; other shards float to their newest release tag |
| Format | `make format` | |
| Lint | `crystal build lib/ameba/src/cli.cr -o bin/ameba`, then `PATH="$PWD/bin:$PATH" make lint` | ameba ships a `targets:` entry, not `executables:`, so `shards install` does not put it on `PATH` |
| Test | `make test` | environment-independent: the test program env is pinned in `new_test_model` |
| Parity | clone `dsisnero/crystal_forge`, run `verify_skill_install.sh . go regex`, then `make inventory` | the gate forwards to that skill; it is not vendored here |

Golden captures do not depend on the host terminal. `Teatest.new_test_model`
sets the program environment to `TERM=xterm-256color` plus
`TERM_PROGRAM=Apple_Terminal`, which keeps Bubble Tea from emitting the
synchronized-output query (`ESC[?2026$p ESC[?2027$p`). The pinned Go upstream
(`bubbletea v2.0.0-rc.1`) has no such query, and its position relative to the
first frame is scheduling-dependent, so suppressing it keeps the byte stream
stable. Reproduce the gate environment locally with:

```bash
env -i HOME="$HOME" PATH="$PATH" crystal spec
```

Because dependencies float, a green local suite with an old `lib/` does not
guarantee a green CI run: `bubbletea` tracks `main`, and a stale
`~/.cache/shards` clone can serve older code. If a fixture suddenly mismatches,
run `make update`, then check `git hash-object lib/bubbletea/src/tea.cr` against
`main` before regenerating anything.

## Project Structure and Porting Notes

- `src/teatest.cr` — the whole library; mirrors `vendor/x/exp/teatest/v2/teatest.go`.
- `spec/` — Crystal specs translated from the upstream Go tests; golden files
  live in `spec/testdata/`.
- `vendor/x` — the `charmbracelet/x` submodule. Only `exp/teatest/v2` is the
  source of truth; `exp/teatest/*.go` is the older v1 code.
- `plans/parity.md` — curated feature roadmap and current state.
- `plans/inventory/` — parity ledger plus generated source/test manifests.
- `lib_issues/` — dependency bug reports named
  `<shard>.<upstream-issue-number>.md` (e.g. `bubbletea.5.md`), renamed to
  `<shard>.<number>.fixed.md` once the upstream fix lands (e.g.
  `bubbletea.1.fixed.md`). Link the upstream issue in the header. Report bugs
  here instead of patching `lib/` in place.
- `scripts/` — forwarding wrappers for the installed parity skill; do not add
  copied skill implementations here.

## Environment Notes

This checkout lives on an external volume where macOS writes AppleDouble `._*`
sidecars next to edited files. `make format`, `make lint`, and `make test`
depend on the `sidecars` target, which deletes them first. See
[resuming.md](resuming.md#environment-notes) for the git-pack workaround.
