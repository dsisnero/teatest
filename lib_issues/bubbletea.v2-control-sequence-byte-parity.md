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
