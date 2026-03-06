# teatest

Crystal port of Go teatest library

## Commands

```bash
# Install dependencies
make install
BEADS_DIR=$(pwd)/.beads shards install

# Update dependencies
make update
BEADS_DIR=$(pwd)/.beads shards update

# Format code
make format
crystal tool format --check

# Lint code
make lint
ameba --fix
ameba

# Run tests
make test
crystal spec -Dpreview_mt -Dexecution_context

# Clean temporary files
make clean
rm -rf ./temp/*
```

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design, data flow, package responsibilities |
| [Development](docs/development.md) | Prerequisites, setup, daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Code style, error handling, naming conventions |
| [Testing](docs/testing.md) | Test commands, conventions, patterns |
| [PR Workflow](docs/pr-workflow.md) | Commits, PRs, branch naming, review process |
| [Porting Parity](docs/porting-parity.md) | Upstream source mapping, behavior parity, test translation |

## Core Principles

1. Upstream Go code (vendor/x/exp/teatest/v2) is the source of truth
2. Preserve behavior exactly; use Crystal idioms without changing semantics
3. When there's conflict between local behavior and Go source, treat v2 files as source-of-truth
4. All porting work must target Bubble Tea v2, so make sure to use vendor/x/exp/teatest/v2

## Commits

Format: `<type>(<scope>): <description>`

Types: feat, fix, docs, refactor, test, chore, perf

### Examples
- `feat(teatest): add send_to_other_program support`
- `fix(golden): handle ANSI escape sequences in output comparison`
- `docs(readme): update installation instructions for Crystal 1.19+`

## Crystal Code Gates

```bash
crystal tool format --check src spec
ameba src spec
crystal spec -Dpreview_mt -Dexecution_context
```

## External Dependencies

- **Go upstream source**: `vendor/x/exp/teatest/v2` - source of truth for behavior
- **Bubble Tea Crystal port**: `dsisnero/bubbletea.cr` - required for Term2 programs
- **Golden testing**: `dsisnero/golden` - for golden file comparisons

Verification:
- Upstream tests pass: `cd vendor/x/exp/teatest && go test ./v2`
- Crystal dependencies install: `shards install`
- Golden file comparisons work: `crystal spec spec/teatest_spec.cr`

## Debugging

When tests fail:
1. Check golden file differences: compare `spec/testdata/*.golden` with actual output
2. Verify upstream behavior: run Go tests in `vendor/x/exp/teatest/v2`
3. Check ANSI escape sequence handling: some tests involve terminal control codes
4. Examine temp directory: `./temp/` may contain test artifacts

Common issues:
- ANSI sequence mismatches between Go and Crystal implementations
- Timing differences in asynchronous test operations
- File path differences between Go and Crystal test runners

## Conventions

- **File naming**: Crystal files use `.cr` extension, test files end with `_spec.cr`
- **Test data**: Golden files go in `spec/testdata/` with `.golden` extension
- **Porting approach**: Translate Go tests to Crystal specs while preserving exact behavior
- **Error handling**: Match Go error messages and semantics where possible
- **Type naming**: Use Crystal naming conventions (CamelCase for classes/modules)