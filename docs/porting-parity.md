---
upstream_repo: "https://github.com/charmbracelet/x"
pinned_revision: "bb9a97036f23256d4201bd73255ca9bd0d2c92f1"
import_mode: "submodule"
upstream_submodule_path: "vendor/x/exp/teatest/v2"
---

# Porting Parity

## Upstream Source of Truth

- Repository: `https://github.com/charmbracelet/x`
- Pinned revision: `bb9a970` (see `git submodule status vendor/x`)
- Import mode: `submodule` (`.gitmodules` → `vendor/x`)
- Upstream path: `vendor/x/exp/teatest/v2`
- Module: `github.com/charmbracelet/x/exp/teatest/v2`

The parent directory `vendor/x/exp/teatest/` still contains the v1 files. They
are **not** the source of truth; only `v2/` is.

## Parity Scope

| Upstream Module/Path | Crystal Target | Status | Notes |
|----------------------|----------------|--------|-------|
| `v2/teatest.go` | `src/teatest.cr` | Ported | Core API + golden wrappers |
| `v2/teatest_test.go` | `spec/teatest_spec.cr` | Ported | WaitFor and timeout specs |
| `v2/app_test.go` | `spec/app_spec.cr` | Ported | Golden-backed example pending review |
| `v2/send_test.go` | `spec/send_spec.cr` | Ported | Golden-backed example pending review |
| `v2/testdata/` | `spec/testdata/` | Copied | Golden files follow Crystal output |

Per-feature status and the current focus live in
[plans/parity.md](../plans/parity.md). Per-symbol status lives in
[plans/inventory/go_port_inventory.tsv](../plans/inventory/go_port_inventory.tsv).

## Behavior Checklist

- [x] Public API surface mapped
- [x] Constants and types ported
- [x] Error semantics matched
- [x] Edge cases mirrored
- [ ] Fixtures/goldens verified (two pending snapshots under review)

## Test Parity

| Upstream Test/Fixture | Crystal Spec | Status | Notes |
|------------------------|--------------|--------|-------|
| `TestRequireEqualOutput` | `spec/teatest_spec.cr` | Ported | Wrapped as `Teatest.require_equal_output` |
| `TestApp` | `spec/app_spec.cr` | Ported | Golden snapshot pending review |
| `TestAppInteractive` | `spec/app_spec.cr` | Ported | Output inspection, no golden |
| `TestAppSendToOtherProgram` | `spec/send_spec.cr` | Ported | Golden snapshot pending review |
| `TestWaitForErrorReader` | `spec/teatest_spec.cr` | Ported | Error message parity |
| `TestWaitForTimeout` | `spec/teatest_spec.cr` | Ported | Timeout message parity |
| `TestWaitFinishedWithTimeoutFn` | `spec/teatest_spec.cr` | Ported | `Teatest::TB` shim |

## Known Deviations

See [divergence.md](../divergence.md) for the full audit. Summary:

- Crystal Bubble Tea/ultraviolet emits terminal capability queries
  (`ESC[?2026$p`, `ESC[?2027$p`) and modify-other-keys mode (`ESC[>4;2m`);
  golden files follow the Crystal byte stream.
- Go `testing.TB` is replaced by the `Teatest::TB` shim and raised exceptions.
- Crystal-only snapshot review helpers (`show_snapshot`, `test_and_review!`,
  `review!`) sit on top of `dsisnero/golden`.

## Verification Commands

```bash
# Verify upstream Go tests pass
cd vendor/x/exp/teatest && go test ./v2

# Crystal quality gates
make format
make lint
make test

# Parity ledger drift check (forwards to the installed parity skill)
make inventory
```

The ledger uses the `tree-sitter` discovery vocabulary
(`PARITY_PARSER ?= tree-sitter` in the `Makefile`). `make inventory` prints
`PARITY_DISCOVERY_BACKEND=chiasmus-tree-sitter` when the Chiasmus toolchain is
available; a `regex` backend means the run is not validating the ledger as
written. See [plans/parity.md](../plans/parity.md) for the migration record.
