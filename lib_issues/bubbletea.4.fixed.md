Upstream issue: https://github.com/dsisnero/bubbletea.cr/issues/4
Follow-up clarification comment: https://github.com/dsisnero/bubbletea.cr/issues/4#issuecomment-3969033733
Self-contained in-repo repro comment: https://github.com/dsisnero/bubbletea.cr/issues/4#issuecomment-3969077692
Renderer-source analysis comment: https://github.com/dsisnero/bubbletea.cr/issues/4#issuecomment-4149206686

## Summary
`bubbletea.cr` output control sequences differ from Go Bubble Tea v2 output used by `x/exp/teatest/v2` golden fixtures. Functional behavior is correct, but strict byte-level golden parity fails for terminal prologue/epilogue and cursor/control sequences.

## Environment
- Crystal: 1.19.1
- OS: macOS (aarch64-apple-darwin25.3.0)
- Shard: bubbletea 0.1.0 (commit `a1430ed5224e1c7c0d0f4efef9e9bc99812c4b29`)
- Host parity target: `vendor/x/exp/teatest/v2`

## Minimal Reproduction
Run Crystal v2 parity specs and compare generated Crystal golden output against Go v2 golden fixtures.

Command:
```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache crystal spec spec/app_spec.cr spec/send_spec.cr
git diff --no-index -- spec/testdata/TestApp.golden vendor/x/exp/teatest/v2/testdata/TestApp.golden
git diff --no-index -- spec/testdata/TestAppSendToOtherProgram.golden vendor/x/exp/teatest/v2/testdata/TestAppSendToOtherProgram.golden
```

## Actual Result
Crystal output bytes differ from Go v2 fixture bytes. Example diff excerpts:

```diff
-\e[?25l\e[?2004h\e[>4;2m\e[=1;1u...
+\e[?2004h\e[>4;1m\e[?4m\e[>1u...
```

```diff
-...All pings:\n... \e[>4m\e[=0;1u\r\e[?2004l\e[J\e[?25h
+...All pings:\n... \r\e[?25h\e[?2004l
```

## Expected Result
When targeting Go `x/exp/teatest/v2` parity, emitted control sequences should match Go Bubble Tea v2 fixture bytes for equivalent scenarios.

## Proposed Fix
Align startup/shutdown and renderer flush control-sequence behavior in `bubbletea.cr` with Go v2 ordering and flags (cursor hide/show, bracketed paste mode, keyboard enhancement negotiation, and clear-screen/reset sequences). A focused regression spec should assert byte equality against the v2 fixture outputs.

## Patch
```diff
# No local shard patch included yet; this issue tracks parity gap and requests upstream alignment.
```

## Verification (2026-11-24, `bubbletea.cr` after the control-sequence and
## renderer work in this stretch)

**This report is stale — the sequences it lists no longer differ from Go.**

The prologue/epilogue listed above (`\e[>4;1m\e[?4m\e[>1u`, `\e[=0;1u`) are
from `bubbletea` `a1430ed` (Crystal 1.19.1). The current port emits what the
pinned Go v2 emits, verified byte for byte:

```bash
# oracle: bubbletea-examples/goldens/quickquit (Go capture, upstream f9df43c)
cd bubbletea-examples/goldens && GODEBUG=randseednop=0 go run ./quickquit \
  > /tmp/go.bin
# and the Crystal port's capture of the same program -> /tmp/crystal.bin
cmp /tmp/go.bin /tmp/crystal.bin    # identical, 81 bytes
```

```
\e[?25l\e[?2004h\e[>4;2m\e[>1u\r\e[Jhello\e[>4m\e[<1u\r\e[J\e[?25h\e[?2004l\e[?2026$p\e[?2027$p
```

The bytes are now pinned by `spec/startup_shutdown_sequences_spec.cr`, so a
regression fails in `bubbletea.cr` rather than in this repository. The remaining
fixture difference is environmental: `TestApp*.golden` in
`vendor/x/exp/teatest/v2/testdata` was captured where
`shouldQuerySynchronizedOutput` was false, so it has no capability query; the
port (and Go, in a bare shell) does query. Regenerate fixtures from Go in the
same environment rather than comparing across environments.

## Suggested teatest-side follow-up

The query-flush boundary also makes two captures non-deterministic (see
[bubbletea.5.md](bubbletea.5.md)). Make `spec/send_spec.cr` independent of it:
keep the programs alive past one frame (≥ 50ms) before quitting, or normalise
the capability query out of both captures before comparing. Implemented as a
50ms settle before the quit keys; see [bubbletea.5.md](bubbletea.5.md).
