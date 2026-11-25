# Divergence Audit: Crystal vs Go v2 (`vendor/x/exp/teatest/v2`)

This file tracks parity status against the Go source-of-truth in:

- upstream repo: `github.com/charmbracelet/x`
- upstream commit: `bb9a97036f23256d4201bd73255ca9bd0d2c92f1`
- `vendor/x/exp/teatest/v2/teatest.go`
- `vendor/x/exp/teatest/v2/teatest_test.go`
- `vendor/x/exp/teatest/v2/app_test.go`
- `vendor/x/exp/teatest/v2/send_test.go`

Current per-feature state: [plans/parity.md](plans/parity.md). Per-symbol
status: [plans/inventory/go_port_inventory.tsv](plans/inventory/go_port_inventory.tsv).

## API parity status

- `Program` interface subset: matched (`send`/`Send` behavior).
- `WithInitialTermSize`: matched.
- `WithProgramOptions`: matched.
- `WaitFor` option defaults and timeout/error string shape: matched.
- `FinalOpts` timeout callbacks (`testing.TB` equivalent): matched via
  `Teatest::TB`.
- `NewTestModel` behavior: matched.
  - default initial size `80x24`
  - apply caller program options
  - append internal options so they override
  - include `with_window_size` from resolved size
- `Type`: matched intent (send per-char key press messages).
- `RequireEqualOutput`: matched behavior in spirit, with Crystal test-name API.

## Test parity status

- `spec/teatest_spec.cr` covers v2 `teatest_test.go` scenarios.
- `spec/app_spec.cr` mirrors `app_test.go` flow and assertions.
- `spec/send_spec.cr` mirrors `send_test.go` flow and strict byte equality
  check.
- Recent upstream test updates changed Go tests to use `tea.View` /
  `tea.NewView(...)`; Crystal already matched that shape, so no `teatest` API
  change was required.

## Known remaining differences

1. **Golden output byte differences**: Crystal golden files follow actual
   Crystal Bubble Tea output. The differences come from the underlying library
   behavior, not from `teatest`:
   - Crystal ultraviolet sends terminal capability queries:
     `ESC[?2026$p ESC[?2027$p` (synchronized output mode and Unicode core mode)
   - Crystal enables modify-other-keys mode 2: `ESC[>4;2m`
   - Different cursor positioning: Crystal uses `ESC[30C` (cursor forward)
     where Go uses a different sequence
   - Go's countdown fixture renders an update with `.\r ESC[A ESC[J ...`, while
     the Crystal fixture emits `ESC[J`, cursor move, and keyboard enhancement
     reset sequences in a different order

   The `TestApp` golden was re-accepted after the dependency refresh, and
   `TestAppSendToOtherProgram` now settles 50ms before quitting so the startup
   capability query is flushed by a renderer tick before shutdown. The
   underlying query-flush boundary is tracked in
   [lib_issues/bubbletea.5.md](lib_issues/bubbletea.5.md); the vendor Go
   fixtures were captured in an environment without the query, so regenerate
   from Go rather than diffing across environments
   ([lib_issues/bubbletea.4.fixed.md](lib_issues/bubbletea.4.fixed.md)).

2. **No Go `testing.TB`**: Crystal does not expose it directly. The port ships
   the `Teatest::TB` shim with `fatal(...)` and raises exceptions elsewhere.

3. **Snapshot review helpers**: `show_snapshot`, `test_and_review!`, and
   `review!` are a Crystal-only extension layered on `dsisnero/golden`, which
   exposes pending-snapshot review. Go relies on `testing.TB` failure hooks
   instead.

## Policy

When behavior questions arise, treat `vendor/x/exp/teatest/v2` as canonical.
Do not pull parity logic from non-v2 `vendor/x/exp/teatest/teatest.go`.
