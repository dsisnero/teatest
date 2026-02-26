Upstream issue: https://github.com/dsisnero/bubbletea.cr/issues/3
Status: parity-invalid for Go `teatest/v2` (keep closed/not planned unless intentionally adding non-parity extension).

## Summary
`bubbletea.cr` does not expose `Tea.with_ansi_compressor`, which is required for parity with Go `teatest` (`tea.WithANSICompressor()`). Expected: `Tea.with_ansi_compressor` exists as a `ProgramOption`. Actual: compile-time error `undefined method 'with_ansi_compressor' for Tea:Module`.

## Environment
- Crystal: 1.19.1
- OS: macOS (aarch64-apple-darwin25.3.0)
- Shard: bubbletea 0.1.0 (commit `a1430ed5224e1c7c0d0f4efef9e9bc99812c4b29`)

## Minimal Reproduction
```crystal
require "bubbletea"

struct M
  include Bubbletea::Model

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    {self, nil}
  end

  def view : Bubbletea::View
    Bubbletea::View.new("")
  end
end

Tea.new_program(M.new, Tea.with_ansi_compressor)
```

Command:
```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache crystal spec
```

## Actual Result
```text
In src/teatest.cr:255:11

 255 | Tea.with_ansi_compressor,
           ^-------------------
Error: undefined method 'with_ansi_compressor' for Tea:Module
```

## Expected Result
`Tea.with_ansi_compressor` is available as a `ProgramOption`, matching Go API surface used by `teatest`.

## Proposed Fix
Add `with_ansi_compressor` in `Tea::Options` and a `Tea.with_ansi_compressor` convenience method. For now, this can safely toggle a program flag (`use_ansi_compressor`) even if compression behavior is implemented later.

## Patch
```diff
+def self.with_ansi_compressor : ProgramOption
+  ->(program : Program) { program.use_ansi_compressor = true }
+end
...
+def self.with_ansi_compressor : ProgramOption
+  Options.with_ansi_compressor
+end
```
