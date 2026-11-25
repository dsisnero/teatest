## Summary
`bubbletea.cr` fails to compile because default arguments reference `Ultraviolet::KeyMod::None`, but `Ultraviolet::KeyMod` is an `Int32` alias (no `None` constant). Expected: shard compiles with `require "bubbletea"`. Actual: compile-time constant resolution error.

## Environment
- Crystal: 1.19.1
- OS: Darwin 25.3.0 (arm64)
- Shard: bubbletea 0.1.0 (commit `a1430ed5224e1c7c0d0f4efef9e9bc99812c4b29`)

## Minimal Reproduction
```crystal
require "bubbletea"
puts Tea.key('a').string
```

Command:
```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache crystal eval 'require "bubbletea"; puts Tea.key('\''a'\'').string'
```

## Actual Result
```text
In lib/bubbletea/src/tea/key.cr:376:50
Error: undefined constant Ultraviolet::KeyMod::None
```

## Expected Result
Code compiles and prints:
```text
a
```

## Proposed Fix
`Ultraviolet::KeyMod` is currently an integer alias. Default values should use `0` (or a dedicated constant defined on Bubble Tea side) instead of `Ultraviolet::KeyMod::None`.

## Patch
```diff
--- a/src/tea/key.cr
+++ b/src/tea/key.cr
@@
-@modifiers : KeyMod = Ultraviolet::KeyMod::None,
+@modifiers : KeyMod = 0,
@@
-def self.key(rune : Char, modifiers : KeyMod = Ultraviolet::KeyMod::None) : Key
+def self.key(rune : Char, modifiers : KeyMod = 0) : Key
@@
-def self.key(type : KeyType, modifiers : KeyMod = Ultraviolet::KeyMod::None) : Key
+def self.key(type : KeyType, modifiers : KeyMod = 0) : Key
--- a/src/tea/mouse.cr
+++ b/src/tea/mouse.cr
@@
-@modifiers : KeyMod = Ultraviolet::KeyMod::None,
+@modifiers : KeyMod = 0,
--- a/src/bubbletea.cr
+++ b/src/bubbletea.cr
@@
-def key(rune_or_type, modifiers = Ultraviolet::KeyMod::None)
+def key(rune_or_type, modifiers = 0)
```
