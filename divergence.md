# Divergence Audit: Crystal vs Go v2 (`vendor/x/exp/teatest/v2`)

This file tracks parity status against Go source-of-truth in:

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

## Known remaining differences

1. Golden output bytes are not byte-identical to Go v2 fixtures for:
- `TestApp.golden`
- `TestAppSendToOtherProgram.golden`

Root cause is in underlying `bubbletea.cr` renderer/control-sequence output, not
in `teatest` API flow. Current Crystal tests enforce strict equality between
local program outputs where Go does (`send_spec`), but project golden files are
Crystal-runtime expected bytes.

2. Crystal does not expose Go `testing.TB` directly.
- Implemented parity shim: `Teatest::TB` with `fatal(...)`.

## Policy

When behavior questions arise, treat `vendor/x/exp/teatest/v2` as canonical.
Do not pull parity logic from non-v2 `vendor/x/exp/teatest/teatest.go`.
