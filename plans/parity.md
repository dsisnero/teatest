# Parity Plan — teatest

Curated feature roadmap for the Crystal port of Go
`github.com/charmbracelet/x/exp/teatest/v2`. Per-symbol state lives in
[plans/inventory/go_port_inventory.tsv](inventory/go_port_inventory.tsv); do not
duplicate it here.

## Where we are

- **Current focus:** none — suite, ledger, parity gates, and CI are green. Pick
  the first item below. The last feature was the tree-sitter ledger migration
  (31 symbols, backend `chiasmus-tree-sitter`).
- **Next up** (ordered; tags: `ready`, `decision`, `periodic`, `blocked`):
  1. **`periodic` Check vendor drift.** `vendor/x` is pinned at `bb9a970`;
     upstream `charmbracelet/x` main is `8aab43e` (checked 2026-11-24). On the
     next bump: `git -C vendor/x checkout <sha>`, `make parity-refresh`, compare
     `plans/inventory/go_source_parity.tsv`/`go_test_parity.tsv`, and add
     `plans/inventory/v<NN>_delta_triage.tsv`. Exit: refreshed manifests, or a
     recorded "no relevant teatest v2 changes" note.
  2. **`blocked` Remove the 50ms settle.** The query race is gone (the test
     program no longer emits the capability query), but the settle still gives
     both programs a renderer tick so the ping frames land in the capture;
     removing it fails 5/5 with an output mismatch. Revisit only if the port
     gains a deterministic "wait for first frame" primitive; otherwise keep it
     and keep the comment accurate.
- **Status by area:**
  - Core functions (`teatest.go`): 9/9 ported.
  - `TestModel` + `SafeReadWriter` methods: 10/10 ported.
  - Types and options (`TestOption`, `WaitForOption`, `FinalOpt`, structs):
    8/8 ported.
  - Test parity (6 upstream tests): 6/6 stable; `send_spec` keeps its 50ms
    render-tick settle.
  - Golden fixtures: regenerated against `bubbletea` `main` (`a1f8c46`, which
    reports `2.1.0+git.commit.a1f8c46`) with a pinned test-program environment;
    no capability-query bytes.
  - Determinism: Go and Crystal captures were compared under five environments
    (`env -i`, `TERM=dumb`, `TERM=xterm-256color`, `+TERM_PROGRAM=WezTerm`,
    `+TERM_PROGRAM=Apple_Terminal`). Each side was byte-identical across all
    five (Go 215 bytes, Crystal 179 bytes); the remaining Go/Crystal difference
    is renderer behavior only.
  - Ledger: 31 symbols tracked with the tree-sitter vocabulary (`class`/
    `function`/`interface`/`method`/`struct`/`type`), validated against Crystal
    discovery; three `alias` types (`FinalOpt`, `TestOption`, `WaitForOption`)
    keep file refs because the vocabulary has no `alias` kind.
  - Snapshot review helpers (`show_snapshot`, `test_and_review!`, `review!`):
    Crystal-only extension, divergence documented; both review helpers return
    pending `*.golden.new` paths, and `test_and_review!` raises on spec failure.
  - Dependency policy: **floating** (decision below). `shard.lock` stays
    gitignored, so `make update`/`make install` may bump `golden`/`bubbletea`
    and invalidate rendering fixtures; treat that as expected churn and
    re-accept fixtures in the bump commit.
- **Scoping notes / gotchas:**
  - The source root is `vendor/x/exp/teatest/v2`, not the parent directory:
    `vendor/x/exp/teatest/*.go` still holds the v1 files with the same names.
  - The curated ledger uses the `tree-sitter` discovery vocabulary
    (`class`/`function`/`interface`/`method`/`struct`/`type`), so the gate
    defaults to `PARITY_PARSER=tree-sitter` and needs the Chiasmus toolchain.
    Confirm `PARITY_DISCOVERY_BACKEND=chiasmus-tree-sitter` in the output; a
    `regex` backend means the run is not validating the ledger as written.
  - Crystal `module` declarations are discovered as `interface` by the native
    vocabulary (`src/teatest.cr::interface::Program`), and class methods carry
    their scope (`src/teatest.cr::method::TestModel.send`).
  - `shards install` resolves what `shard.yml` asks for: `bubbletea` now pins
    `branch: main` explicitly, so installs take branch HEAD (`a1f8c46` today,
    reported as `2.1.0+git.commit…`), while unversioned shards such as `golden`
    resolve their newest release tag. `make update` refreshes `bubbletea` to the
    current `main`; run it before accepting rendering changes.
  - A stale `~/.cache/shards` clone can serve an older commit or another
    branch; if `lib/` disagrees with a clean-room install, re-clone the cache
    entry and reinstall.
  - A previous local `lib/bubbletea` came from the
    `codex/flush-initial-frame` branch and hid the divergence. Check
    `git hash-object lib/bubbletea/src/tea.cr` against `main` before trusting a
    local capture.
  - `Teatest.new_test_model` pins the test program's environment
    (`TERM=xterm-256color`, `TERM_PROGRAM=Apple_Terminal`) so Bubble Tea never
    emits `ESC[?2026$p ESC[?2027$p`. The pinned Go upstream
    (`bubbletea v2.0.0-rc.1`) has no such query, and emitting it made the byte
    stream scheduling-dependent. Override via `with_program_options` when a test
    needs real environment values.
  - `bubbletea.cr`/`ultraviolet` still emit modify-other-keys mode
    (`ESC[>4;2m`) and render diffs (`ESC[30C`) differently from the pinned Go
    renderer; that is the documented byte-stream divergence, not a bug.
  - `send_spec` must keep both programs alive past a renderer tick (≥50ms)
    before quitting, otherwise the ping frames never reach the capture and the
    golden compare fails.
  - `.golden.new` (pending review) and `*.golden.meta` (golden metadata) are
    artifacts, not fixtures; never commit them.
- **Last feature commit:** `cd2227f` (`chore(parity): migrate the ledger to
  tree-sitter ids`) plus `c719250` (CI tree-sitter runtime); before that
  `c8e0883` (bubbletea main), `2ba58d7` (determinism), `ff44b6b` (CI workflow)
- **Gates:** `make format` pass; `make lint` pass; `make test` 14 examples,
  0 failures on 5 consecutive runs after the `bubbletea` `main` refresh;
  `make inventory` pass (31 items tracked, backend `chiasmus-tree-sitter`,
  Crystal symbols validated); kind-vocabulary scan reports no drops;
  clean-room CI simulation pass end-to-end; parity preflight
  `PARITY_SKILL_VERIFIED=1`; GitHub `CI` runs `45567742970`, `45568077827`,
  `45568476812`, `45570459526`, and `45577329581` success (the last confirms
  backend `chiasmus-tree-sitter` and 31 items on the runner).

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
- [x] Return pending snapshot paths from `review!` and `test_and_review!`, keep
      printing for humans, and raise when the spec command fails
      (`spec/teatest_spec.cr` pending/empty/failing cases)
- [x] Accept the reviewed `TestApp` golden and the current send fixture
- [x] Keep `spec/testdata/` in sync with the accepted behavior

## Phase 4 — Parity ledger hygiene

- [x] Rebase the ledger on the v2 baseline and drop duplicate v1 rows
- [x] Forward parity scripts to the installed canonical skill
- [x] Migrate `crystal_refs` to symbol refs and validate them with
      `PORT_CRYSTAL_SOURCE=src` (Crystal `alias` types keep file refs until the
      tree-sitter vocabulary is adopted)
- [x] Review the tree-sitter migration candidate (assessment below)
- [x] Migrate the ledger to tree-sitter ids: 31 symbols, native Crystal symbol
      refs (`method::Class.name`, `module` → `interface`), `PARITY_PARSER`
      default switched, CI preflight resolves the toolchain

## Phase 5 — Dependency alignment

- [x] Make `spec/send_spec.cr` independent of the capability-query flush
      boundary: keep both programs alive 50ms past a renderer tick before
      quitting ([lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md))
- [x] Pin the test-program environment so the capability query is never emitted
      and the byte stream no longer depends on the host terminal; refresh the
      goldens against the resolved `bubbletea` `v2.0.8` tag
- [x] Verify Go/Crystal determinism under five environments (each side
      byte-identical; remaining differences are renderer-only)
- [ ] Remove the settle: keeps the renderer tick that paints the ping frames, so
      it stays until the port has a deterministic first-frame primitive

## Continuous integration (2026-11-25)

`.github/workflows/ci.yml` runs `make format`, `make lint`, `make test`, and the
parity preflight plus `make inventory` on push/PR. It checks out submodules,
installs Crystal 1.22.3 (the compiler that accepted the fixtures), installs
floating shards, builds `ameba` from the locked dependency (the shard exposes a
`targets:` entry, not `executables:`), builds and caches the `tree-sitter`
v0.26 runtime (the Chiasmus Linux binary needs `libtree-sitter.so.0.26`, which
Ubuntu does not ship), caches `~/.cache/chiasmus`, clones
`dsisnero/crystal_forge` for `PARITY_SKILL_DIR`, and resolves the tree-sitter
toolchain with `verify_skill_install.sh . go tree-sitter`.

A clean-room clone (no lock, empty `lib/`) reproduces the gates locally with the
same commands, and GitHub run `45568077827` (`df0483a`, 2m31s) passed all of
them. The workflow does not pin `TERM`: the test-program environment is pinned
inside `new_test_model`, so captures are environment-independent.

## Dependency policy decision (2026-11-24)

`/shard.lock` stays gitignored: **dependencies remain floating**.

- Rationale: the port tracks unreleased Crystal shards (`bubbletea.cr`,
  `golden`, `ultraviolet`), so floating pulls fixes without ceremony; rendering
  fixture churn after `make update` is expected and is re-accepted in the bump
  commit (as with `golden` 0.2.0 → 0.3.0).
- Consequences: `make install`/`make update` can change the byte stream, so
  never commit a fixture diff without naming the dependency change; CI has no
  lock to restore and reinstalls from scratch.
- Resolution behavior (verified 2026-11-25): `bubbletea` pins `branch: main`, so
  a lock-free install takes branch HEAD (`a1f8c46`, reported as
  `2.1.0+git.commit…`); unversioned shards such as `golden` still resolve their
  newest release tag. `make update` moves `bubbletea` to the current `main`, so
  run it before accepting rendering changes. A stale `~/.cache/shards` clone can
  serve an older commit or another branch; inspect
  `git hash-object lib/<shard>/src/...` against `main` before trusting a capture.
- Revisit if: two machines disagree on a fixture, or an upstream regression
  cannot be attributed without a bisectable lock. (The 2026-11-25 fixture drift
  had this trigger fire, but the cause was a branch-local `lib/` install and a
  stale cache rather than floating versions.)

## Tree-sitter ledger migration (assessed 2026-11-24, completed 2026-11-25)

Assessed a native candidate for `vendor/x/exp/teatest/v2` with
`PORT_PARSER=tree-sitter` (backend `chiasmus-tree-sitter`, toolchain v0.3.4):

- 31 declarations vs 27 in the regex ledger.
- Every id changes kind: `func` → `function`, `struct` → `class`,
  `type::Program` → `interface::Program`.
- Adds four internal declarations the regex extractor skips: `safe`,
  `doWaitFor`, `safeReadWriter`, `waitDone`.

Completed migration (one reviewed change):

- All ids re-based on the tree-sitter vocabulary; `safe` is recorded as
  `intentional_divergence` (the Crystal port constructs `SafeReadWriter`
  directly), and the four internals are tracked with their private Crystal
  counterparts (`Teatest.do_wait_for`, `TestModel.wait_done`).
- `crystal_refs` now use native scoped symbols
  (`src/teatest.cr::method::TestModel.send`); Crystal `module` declarations are
  discovered as `interface`, so `Teatest::Program` is
  `src/teatest.cr::interface::Program`.
- The three `alias` types still use file refs: the vocabulary has no `alias`
  kind, which the original assessment assumed would be solved by the migration.
- `PARITY_PARSER` defaults to `tree-sitter`; CI caches `~/.cache/chiasmus`,
  runs the tree-sitter preflight, and `make inventory` fails loudly instead of
  falling back to regex because the mode is explicit.
- `make inventory`: 31 items tracked, backend `chiasmus-tree-sitter`.

## Intentional divergences

- Snapshot review helpers (`show_snapshot`, `test_and_review!`, `review!`):
  Go relies on `testing.TB` failure hooks; the Crystal port layers these on
  `dsisnero/golden`, which exposes pending-snapshot review instead. The review
  helpers return pending `*.golden.new` paths, and `test_and_review!` raises on
  spec failure instead of returning an error sentinel.
- `Teatest.new_test_model` does not take a `testing.TB` equivalent: Crystal
  `Spec` failures are global, so errors are raised as exceptions.
- `TestModel#send` accepts non-`Tea::Msg` values through `Tea.wrap`, mirroring
  Go's `interface{}` message type.
- Golden bytes follow Crystal Bubble Tea/ultraviolet output ordering rather
  than the Go byte stream (see [divergence.md](../divergence.md)).
- `Teatest.new_test_model` pins the test program's environment
  (`TERM=xterm-256color`, `TERM_PROGRAM=Apple_Terminal`) so Bubble Tea's
  terminal heuristic never emits the synchronized-output query. The pinned Go
  upstream (`bubbletea v2.0.0-rc.1`) has no such query, and emitting it made the
  byte stream depend on renderer scheduling. Override with
  `with_program_options` when a test needs real environment values.
- `spec/send_spec.cr` sleeps 50ms after the pings and before the quit keys so
  both programs reach a renderer tick and the ping frames are painted into the
  capture ([lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md)).
