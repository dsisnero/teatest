# Parity Plan — teatest

Curated feature roadmap for the Crystal port of Go
`github.com/charmbracelet/x/exp/teatest/v2`. Per-symbol state lives in
[plans/inventory/go_port_inventory.tsv](inventory/go_port_inventory.tsv); do not
duplicate it here.

## Where we are

- **Current focus:** vendor dependency refresh. `make update` pulled `golden`
  0.3.0 and newer `ultraviolet`/`ansi`; the rendering bytes changed, fixtures
  were re-accepted in the new environment, and `send_spec` now keeps both
  programs alive for 50ms before quitting so it no longer straddles the
  capability-query flush boundary
  ([lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md)).
  10/10 full-suite runs pass.
- **Next up:**
  1. Track
     [lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md)
     upstream; once the query boundary is deterministic, drop the 50ms settle
     in `spec/send_spec.cr`. Do not patch `lib/`.
  2. Treat the tree-sitter ledger migration as a dedicated reviewed change
     (assessment below); it is not worth interrupting the current ledger.
  3. On an upstream bump, refresh the manifests with `make parity-refresh` and
     write a `plans/inventory/v<NN>_delta_triage.tsv` for that release.
- **Status by area:**
  - Core functions (`teatest.go`): 9/9 ported.
  - `TestModel` + `SafeReadWriter` methods: 10/10 ported.
  - Types and options (`TestOption`, `WaitForOption`, `FinalOpt`, structs):
    8/8 ported.
  - Test parity (6 upstream tests): 6/6 stable after the `send_spec` settle.
  - Golden fixtures: re-accepted after the dependency refresh (testdata now
    reflects the installed `golden`/`ultraviolet`/`ansi` rendering).
  - Ledger refs: 24/27 symbol-validated (`path::kind::name`); the three
    Crystal `alias` types keep file refs because the regex vocabulary does not
    discover aliases.
  - Snapshot review helpers (`show_snapshot`, `test_and_review!`, `review!`):
    Crystal-only extension, divergence documented.
- **Scoping notes / gotchas:**
  - The source root is `vendor/x/exp/teatest/v2`, not the parent directory:
    `vendor/x/exp/teatest/*.go` still holds the v1 files with the same names.
  - The curated ledger uses the `regex` discovery vocabulary
    (`func`/`method`/`struct`/`type`), so pin `PORT_PARSER=regex`; the
    tree-sitter candidate was reviewed and deferred (assessment below).
  - Fixtures are environment-sensitive: the vendor Go goldens were captured
    where `shouldQuerySynchronizedOutput` was false, so do not diff them against
    a bare-shell Crystal capture (see
    [lib_issues/bubbletea.4.fixed.md](../lib_issues/bubbletea.4.fixed.md)).
  - `send_spec` must keep both programs alive past a renderer tick (≥50ms)
    before quitting; a send-only failure whose outputs differ solely in the
    position of `ESC[?2026$p ESC[?2027$p` means that settle was lost. Do not
    "fix" it by normalizing the fixture
    ([lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md)).
  - `.golden.new` files are review artifacts, not fixtures; never commit them.
  - `bubbletea.cr`/`ultraviolet` emit terminal capability queries
    (`ESC[?2026$p`, `ESC[?2027$p`) and modify-other-keys mode
    (`ESC[>4;2m`) that Go only emits in a querying environment.
- **Last feature commit:** `44101b0` (`docs(lib_issues): number shard bug
  reports and mark fixed ones`); earlier `dd0267c` (ledger symbol refs) and
  `dbad171` (parity tooling adoption)
- **Gates:** `make format` pass; `make lint` pass; `make test` 12 examples,
  0 failures on 10 of 10 runs; `make inventory` pass (27 items tracked, backend
  `regex`, Crystal symbols validated); adversarial signoff pass (`crystal spec`
  + upstream `go test ./...`).

Keep this block accurate after every feature: the next session reads it first
(see [AGENTS.md](../AGENTS.md) → **How to resume**).

## Phase 1 — Core API surface

- [x] Port `Program`, `TestModelOptions`, `TestOption`, `WithInitialTermSize`
- [x] Port `WithProgramOptions` and the option-override ordering
- [x] Port `WaitFor`, `WaitingForContext`, `WaitForOption`,
      `WithCheckInterval`, `WithDuration`
- [x] Port `FinalOpts`, `FinalOpt`, `WithTimeoutFn`, `WithFinalTimeout`
- [x] Port `TestModel` methods (`Send`, `Type`, `Quit`, `Output`, `FinalModel`,
      `FinalOutput`, `WaitFinished`, `GetProgram`)
- [x] Port `safeReadWriter` as `Teatest::SafeReadWriter`
- [x] Provide the `Teatest::TB` shim for Go's `testing.TB`

## Phase 2 — Test parity

- [x] Port `TestApp` flow and assertions (`spec/app_spec.cr`)
- [x] Port `TestAppInteractive` (`spec/app_spec.cr`)
- [x] Port `TestAppSendToOtherProgram` (`spec/send_spec.cr`)
- [x] Port `TestWaitForErrorReader`, `TestWaitForTimeout`,
      `TestWaitFinishedWithTimeoutFn` (`spec/teatest_spec.cr`)
- [x] Make `TestApp` pass without pending snapshots
- [x] Make `TestAppSendToOtherProgram` pass without pending snapshots
      (50ms settle before quit keeps both programs past a renderer tick)

## Phase 3 — Snapshot workflow

- [x] Add `show_snapshot`, `test_and_review!`, `review!` wrappers
- [x] Accept the reviewed `TestApp` golden and the current send fixture
- [x] Keep `spec/testdata/` in sync with the accepted behavior

## Phase 4 — Parity ledger hygiene

- [x] Rebase the ledger on the v2 baseline and drop duplicate v1 rows
- [x] Forward parity scripts to the installed canonical skill
- [x] Migrate `crystal_refs` to symbol refs and validate them with
      `PORT_CRYSTAL_SOURCE=src` (Crystal `alias` types keep file refs until the
      tree-sitter vocabulary is adopted)
- [x] Review the tree-sitter migration candidate (assessment below)
- [ ] Migrate the ledger to tree-sitter ids as a dedicated reviewed change

## Phase 5 — Dependency alignment

- [x] Make `spec/send_spec.cr` independent of the capability-query flush
      boundary: keep both programs alive 50ms past a renderer tick before
      quitting ([lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md))
- [ ] Remove the settle once the boundary is deterministic upstream and the
      fixtures can be regenerated in the same environment

## Tree-sitter candidate assessment (2026-11-24)

Generated a native candidate for `vendor/x/exp/teatest/v2` with
`PORT_PARSER=tree-sitter` (backend `chiasmus-tree-sitter`, toolchain v0.3.4):

- 31 declarations vs 27 in the regex ledger.
- Every id changes kind: `func` → `function`, `struct` → `class`,
  `type::Program` → `interface::Program`.
- Adds four internal declarations the regex extractor skips: `safe`,
  `doWaitFor`, `safeReadWriter`, `waitDone`.
- No `definition.type` rows; the kind-vocabulary gate reports no drops.

Decision: keep `PORT_PARSER=regex` and the current ledger. Migrating would
rewrite all 27 ids and pull in internal helpers; do it as its own reviewed
change with a re-based ledger and a fresh `crystal_refs` migration.

## Intentional divergences

- Snapshot review helpers (`show_snapshot`, `test_and_review!`, `review!`):
  Go relies on `testing.TB` failure hooks; the Crystal port layers these on
  `dsisnero/golden`, which exposes pending-snapshot review instead.
- `Teatest.new_test_model` does not take a `testing.TB` equivalent: Crystal
  `Spec` failures are global, so errors are raised as exceptions.
- `TestModel#send` accepts non-`Tea::Msg` values through `Tea.wrap`, mirroring
  Go's `interface{}` message type.
- Golden bytes follow Crystal Bubble Tea/ultraviolet output ordering rather
  than the Go byte stream (see [divergence.md](../divergence.md)).
- `spec/send_spec.cr` sleeps 50ms after the pings and before the quit keys so
  both programs are alive past a renderer tick; without it the startup
  capability query can flush on either side of the shutdown epilogue
  ([lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md)).
