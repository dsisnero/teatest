Upstream issue: not filed yet (candidate number:
https://github.com/dsisnero/bubbletea.cr/issues/5)

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

## Verification (2026-11-24, `bubbletea.cr` after the control-sequence and
## renderer work in this stretch)

**The flakiness is real, but its stated cause is not a `bubbletea.cr` bug: Go
behaves the same way.**

Go's capability query sits in the program's output buffer and is flushed by
whichever comes first — a renderer tick, or `restoreTerminalState` at shutdown
(`vendor/bubbletea` `tty.go:34`, which runs after `stopRenderer`). A Go probe of
the same model (`bubbletea-examples/goldens/quickquit`) shows both positions:

```
delay 0s   query at  63 len  81     # quit before the first tick -> after epilogue
delay 20ms query at   0 len  85     # a tick flushed it first   -> before the frame
```

The Crystal port produces exactly these bytes for the same two timings
(`spec/startup_shutdown_sequences_spec.cr` pins the first case against Go), so
`out1 == out2` can only hold when both programs land on the same side of that
boundary. `x/exp/teatest/v2`'s fixture never shows the problem because it was
captured where `shouldQuerySynchronizedOutput` was false, so Go emitted no query
at all.

Two things were still changed on the `bubbletea.cr` side:

- the renderer stop handshake now waits for the renderer fiber to exit, matching
  Go's unbuffered `rendererDone` rendezvous, so a tick in flight can never flush
  a frame or queued output after `renderer.close` wrote the epilogue;
- `spec/startup_shutdown_sequences_spec.cr` pins Go's exact startup/shutdown
  bytes (including the query position) with an explicit empty environment, so the
  port's side of this is regression-tested.

## Suggested teatest-side follow-up (implemented 2026-11-24)

Make `send_spec` independent of the boundary: either keep the programs alive for
more than one frame (≥ 50ms) before quitting, so the query is always flushed by
a tick, or normalise the capability query out of both captures before comparing.

`spec/send_spec.cr` now sleeps 50ms after the pings and before the quit keys, so
both programs remain alive past a renderer tick. The spec passed 10/10
full-suite runs with that settle. This report stays open so the workaround can
be removed once the boundary is deterministic upstream.

## Resolution for teatest (2026-11-25)

`Teatest.new_test_model` now pins the program environment
(`TERM=xterm-256color`, `TERM_PROGRAM=Apple_Terminal`) instead of inheriting the
host environment. Bubble Tea's terminal heuristic then reports a non-querying
terminal and the capability query is never emitted, so the query-position race
cannot affect a capture.

This matches the pinned Go upstream: the `charm.land/bubbletea/v2 v2.0.0-rc.1`
module required by `vendor/x/exp/teatest/v2` contains no synchronized-output
query at all. The query is a `bubbletea.cr` divergence from that release, not
something the Go fixture ever contained.

Evidence (same machine; `TestApp` scenario captured from Go and from the port
under five environments: `env -i`, `TERM=dumb`, `TERM=xterm-256color`,
`... TERM_PROGRAM=WezTerm`, `... TERM_PROGRAM=Apple_Terminal`):

- Go: 215 bytes, byte-identical in all five environments, no query bytes.
- Port after the pin: 179 bytes, byte-identical in all five environments, no
  query bytes (captured against `bubbletea` `main` `a1f8c46`).
- The remaining Go/Crystal differences are the renderer divergences documented
  in `divergence.md` (modify-other-keys mode, `ESC[30C` tail update versus
  `.\r ESC[A ESC[J`, shutdown epilogue order), not environment effects.

The 50ms settle in `spec/send_spec.cr` stays, but for a different reason: it
keeps both programs alive long enough to paint the ping frames that the golden
captures. Removing it fails 5/5 runs with an output mismatch (the captures have
no ping frames), so it is load-bearing for the fixture rather than a race
guard. The comment in the spec says so.

