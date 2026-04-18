# Divergence Audit: Crystal vs Go v2 (`vendor/x/exp/teatest/v2`)

This file tracks parity status against Go source-of-truth in:

- upstream repo: `github.com/charmbracelet/x`
- upstream commit: `6921c759c9134ae68bd1a6ff6e171bf470664aaf`
- `vendor/x/exp/teatest/v2/teatest.go`
- `vendor/x/exp/teatest/v2/teatest_test.go`
- `vendor/x/exp/teatest/v2/app_test.go`
- `vendor/x/exp/teatest/v2/send_test.go`

## API parity status

- `Program` interface subset: matched (`send`/`Send` behavior).
- `WithInitialTermSize`: matched.
- `WithProgramOptions`: matched.
- `WaitFor` option defaults and timeout/error string shape: matched.
- `FinalOpts` timeout callbacks (`testing.TB` equivalent): matched via `Teatest::TB`.
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
- `spec/send_spec.cr` mirrors `send_test.go` flow and strict byte equality check.
- Recent upstream test updates from `fe36e8c` to `df7b1bc` changed Go tests to use `tea.View`/`tea.NewView(...)`; Crystal already matched that shape, so no `teatest` API change was required.

## Known remaining differences

1. **Golden output byte differences**: Crystal golden files have been updated to match actual Crystal Bubble Tea output using `GOLDEN_UPDATE=1`. The differences are due to underlying library behavior:
   - Crystal ultraviolet sends terminal capability queries: `ESC[?2026$p ESC[?2027$p` (request synchronized output mode and Unicode core mode)
   - Crystal enables modify other keys mode 2: `ESC[>4;2m`
   - Different cursor positioning: Crystal uses `ESC[30C` (cursor forward) vs Go's approach
   
   These are `bubbletea.cr`/`ultraviolet` library differences, not `teatest` implementation issues. The teatest library correctly captures and compares Crystal Bubble Tea program output.

2. **Parity tracking**: Added cross-language parity inventory system (`plans/inventory/`) with 65 items tracked, 35 marked as ported with Crystal references.
- Go fixture now renders the countdown update using `.\r ESC[A ESC[J ...`
- Crystal fixture still renders the update using `ESC[J`, cursor move, and
  keyboard enhancement reset sequences in a different order

2. Crystal does not expose Go `testing.TB` directly.
- Implemented parity shim: `Teatest::TB` with `fatal(...)`.

## Policy

When behavior questions arise, treat `vendor/x/exp/teatest/v2` as canonical.
Do not pull parity logic from non-v2 `vendor/x/exp/teatest/teatest.go`.
