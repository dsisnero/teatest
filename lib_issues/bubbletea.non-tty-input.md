## Summary
Programs created with non-TTY input/output (for tests) fail with `not a terminal` because `Tea::Program#init_input` unconditionally calls `Console#make_raw`. Expected Go parity: `WithInput(IO)` + `WithOutput(IO)` should work for teatest-style non-terminal buffers.

## Environment
- Crystal: 1.19.1
- OS: Darwin 25.3.0 (arm64)
- Shard: bubbletea 0.1.0 (commit `a1430ed5224e1c7c0d0f4efef9e9bc99812c4b29`)

## Minimal Reproduction
```crystal
require "bubbletea"

struct M
  include Tea::Model

  def init : Tea::Cmd?
    Tea.quit
  end

  def update(msg : Tea::Msg)
    {self, nil}
  end

  def view : Tea::View
    Tea::View.new("ok")
  end
end

input = IO::Memory.new
output = IO::Memory.new
p = Tea.new_program(M.new, Tea.with_input(input), Tea.with_output(output), Tea.without_signals)
model, err = p.run
pp({model.class.name, err.nil?})
```

Command:
```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache crystal eval 'require "bubbletea"; struct M; include Tea::Model; def init : Tea::Cmd?; Tea.quit; end; def update(msg : Tea::Msg); {self, nil}; end; def view : Tea::View; Tea::View.new("ok"); end; end; input=IO::Memory.new; output=IO::Memory.new; p=Tea.new_program(M.new, Tea.with_input(input), Tea.with_output(output), Tea.without_signals); model, err = p.run; puts({model.class.name, err.nil?}.inspect)'
```

## Actual Result
```text
not a terminal (Exception)
  from lib/ultraviolet/src/ultraviolet/console.cr:140:5 in 'make_raw_impl'
  ...
  from lib/bubbletea/src/tea/tty.cr:218:24 in 'init_input'
```

## Expected Result
Program should run in non-interactive mode and return:
```text
{"M", true}
```

## Proposed Fix
Guard raw-mode setup behind TTY checks. If input/output are non-TTY custom IOs, skip `Console#make_raw` and continue.

## Patch
```diff
--- a/src/tea/tty.cr
+++ b/src/tea/tty.cr
@@
+input_is_tty = @tty_input.try(&.tty?) || false
+output_is_tty = @tty_output.try(&.tty?) || false
+return nil unless input_is_tty && output_is_tty
+
 @console = Ultraviolet::Console.new(@input, @output, @env.items)
 @console.try(&.make_raw)
```
