# Parity Plan — teatest

Curated feature roadmap for the Crystal port of Go
`github.com/charmbracelet/x/exp/teatest/v2`. Per-symbol state lives in
[plans/inventory/go_port_inventory.tsv](inventory/go_port_inventory.tsv); do not
duplicate it here.

## Where we are

- **Current focus:** `TestAppSendToOtherProgram` is flaky. The two programs
  differ only in where `bubbletea.cr` flushes its startup capability queries
  (`ESC[?2026$p ESC[?2027$p`), so `out1.should eq out2` and the golden compare
  fail in roughly 1 of 5 full-suite runs. Root cause and repro:
  [lib_issues/bubbletea.capability-query-race.md](../lib_issues/bubbletea.capability-query-race.md).
- **Next up:**
  1. Fix the capability-query ordering upstream in `dsisnero/bubbletea.cr`
     (or carry a reviewed local shard patch via `crystal-shard-lib-patch`),
     then make the send spec pass 5/5 runs.
  2. Migrate ledger `crystal_refs` from file paths to
     `path::kind::name` symbol refs with the canonical
     `migrate_crystal_refs.py` (`--crystal-source src`) so renames inside
     `src/teatest.cr` are caught.
  3. Evaluate a tree-sitter ledger migration: generate a native candidate,
     audit `definition.type` captures and duplicates, and only then switch
     `PARITY_PARSER` in a reviewed commit.
  4. On an upstream bump, refresh the manifests with `make parity-refresh` and
     write a `plans/inventory/v<NN>_delta_triage.tsv` for that release.
- **Status by area:**
  - Core functions (`teatest.go`): 9/9 ported.
  - `TestModel` + `SafeReadWriter` methods: 10/10 ported.
  - Types and options (`TestOption`, `WaitForOption`, `FinalOpt`, structs):
    8/8 ported.
  - Test parity (6 upstream tests): 5 stable; `TestAppSendToOtherProgram`
    ported but flaky on the dependency race above.
  - Golden fixtures: `TestApp` accepted against current Crystal output; send
    fixture current but the spec around it is racy.
  - Snapshot review helpers (`show_snapshot`, `test_and_review!`, `review!`):
    Crystal-only extension, divergence documented.
- **Scoping notes / gotchas:**
  - The source root is `vendor/x/exp/teatest/v2`, not the parent directory:
    `vendor/x/exp/teatest/*.go` still holds the v1 files with the same names.
  - The curated ledger uses the `regex` discovery vocabulary
    (`func`/`method`/`struct`/`type`), so pin `PORT_PARSER=regex` until the
    tree-sitter migration is reviewed.
  - A send-only failure whose two outputs differ solely in the position of
    `ESC[?2026$p ESC[?2027$p` is this dependency race, not golden drift. Do not
    "fix" it by normalizing the fixture.
  - `.golden.new` files are review artifacts, not fixtures; never commit them.
  - `bubbletea.cr`/`ultraviolet` emit terminal capability queries
    (`ESC[?2026$p`, `ESC[?2027$p`) and modify-other-keys mode
    (`ESC[>4;2m`) that Go does not, which is the source of golden drift.
- **Last feature commit:** `dbad171` (`chore(parity): adopt canonical parity
  tooling and review golden fixtures`); previous feature `5545ced`
  (`feat(teatest): add show_snapshot, test_and_review!, review! wrappers`)
- **Gates:** `make format` pass; `make lint` pass; `make test` 12 examples,
  0 failures on 4 of 5 runs (1 send flake, above); `make inventory` pass
  (27 items tracked, backend `regex`); upstream `go test ./...` in
  `vendor/x/exp/teatest/v2` pass.

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
- [ ] Make `TestAppSendToOtherProgram` pass without pending snapshots
      (blocked on the capability-query ordering race)

## Phase 3 — Snapshot workflow

- [x] Add `show_snapshot`, `test_and_review!`, `review!` wrappers
- [x] Accept the reviewed `TestApp` golden and the current send fixture
- [x] Keep `spec/testdata/` in sync with the accepted behavior

## Phase 4 — Parity ledger hygiene

- [x] Rebase the ledger on the v2 baseline and drop duplicate v1 rows
- [x] Forward parity scripts to the installed canonical skill
- [ ] Migrate `crystal_refs` to symbol refs
- [ ] Review the tree-sitter migration candidate

## Phase 5 — Dependency alignment

- [ ] Fix the `bubbletea.cr` capability-query ordering race
      ([lib_issues/bubbletea.capability-query-race.md](../lib_issues/bubbletea.capability-query-race.md))
      and make the send spec deterministic

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
