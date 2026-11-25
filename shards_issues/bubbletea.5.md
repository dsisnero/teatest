Shard: `bubbletea` 2.0.8 ([dsisnero/bubbletea.cr](https://github.com/dsisnero/bubbletea.cr))
Upstream issue: pending — next free number is
https://github.com/dsisnero/bubbletea.cr/issues/5 (renumber this file if the
issue lands differently).

## Summary
`bubbletea.cr` emits its startup terminal capability queries
(`ESC[?2026$p` + `ESC[?2027$p`) through the renderer's `@output_buf`, so their
position relative to the shutdown epilogue is scheduling-dependent. Two
programs running the same scenario can therefore produce byte-different output
even though the rendered frames are identical. This makes
`TestAppSendToOtherProgram`'s `out1 == out2` assertion and its golden compare
flaky in the Crystal port; Go v2 is stable.

## Environment
- Crystal: 1.22.3
- OS: macOS (arm64, darwin27)
- Shard: bubbletea 2.0.8
- Swallowed via: `lib/` (shards install), no local patch applied
- Host parity target: `vendor/x/exp/teatest/v2`

## Minimal Reproduction
```bash
crystal spec spec/send_spec.cr
```

Repeat the run several times; roughly 1 in 5 full-suite runs fails.

## Actual Result
The two captured outputs are byte-identical except for the query position. From
a failing run (302 bytes each, `repr` of the decoded capture):

```
out1: ...from m2\e[?2026$p\e[?2027$p\e[>4m\e[=0;1u\r\e[J\e[?25h\e[?2004l
out2: ...from m2\e[>4m\e[=0;1u\r\e[J\e[?25h\e[?2004l\e[?2026$p\e[?2027$p
```

The trailing position (after `ESC[?2004l`, i.e. after bracketed-paste mode was
disabled) also means the query is delivered too late for a real terminal to
answer it.

## Expected Result
The capability queries are written once, synchronously, before the first frame
is flushed, so every program instance emits the same prefix and the output is
byte-stable across runs. Go v2 output used by `x/exp/teatest/v2` is stable.

## Root Cause
`lib/bubbletea/src/tea.cr`:

```crystal
start_renderer

# Match Go behavior: query synchronized output support by default.
if !@disable_renderer && should_query_synchronized_output(@env)
  execute(Ansi::RequestModeSynchronizedOutput + Ansi::RequestModeUnicodeCore)
end
```

`execute` appends to the renderer output buffer under `@mutex`
(`lib/bubbletea/src/tea.cr:893`), while the renderer flush runs on its own
schedule. When the program quits immediately after startup (as
`TestAppSendToOtherProgram` does), the append can land after the final flush and
the shutdown epilogue, producing the trailing variant above.

## Proposed Fix
Emit the capability query before the first render/flush (write it directly to
the output rather than through the deferred buffer), or drain `@output_buf`
deterministically during `shutdown`. A focused regression spec should assert
that two identical programs produce equal byte streams and that
`ESC[?2026$p ESC[?2027$p` precedes the first frame.

## Patch
```diff
# No local shard patch included; this issue tracks the ordering race and requests
# upstream alignment.
```

## Impact on this repository
- `spec/send_spec.cr` asserts `out1 == out2` (upstream parity) and then compares
  against `spec/testdata/TestAppSendToOtherProgram.golden`; either assertion can
  fail on the race.
- The ledger keeps `TestAppSendToOtherProgram` at `partial` and
  `plans/parity.md` tracks the dependency fix as the top open item.
