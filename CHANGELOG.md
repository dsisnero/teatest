# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- Added `.github/workflows/ci.yml` running `make format`, `make lint`,
  `make test`, and the parity preflight plus `make inventory` on push and pull
  requests.
- `Teatest.new_test_model` pins the test program's environment
  (`TERM=xterm-256color`, `TERM_PROGRAM=Apple_Terminal`) so Bubble Tea does not
  emit synchronized-output capability queries; golden captures no longer depend
  on the host terminal. Override with `Teatest.with_program_options`.
- `shard.yml` now tracks `bubbletea` from `main` explicitly (it previously
  resolved the newest release tag, `v2.0.8`); the refreshed fixtures reflect
  `main` at `a1f8c46` and no longer contain `ESC[?2026$p ESC[?2027$p`.
- Ignore `*.golden.meta` alongside pending snapshots.
- `Teatest.review!` now returns the pending `*.golden.new` paths (still printed
  for humans) and accepts an optional `io`.
- `Teatest.test_and_review!` now returns the pending snapshot paths and raises
  when the spec command fails, instead of returning an `{"error", message}`
  sentinel tuple.

## [0.2.0] - 2026-07-27

- Added `show_snapshot` to read golden snapshot files
- Added `test_and_review!` to run specs then review pending snapshots
- Added `review!` to list pending golden snapshots

## [0.1.0] - 2026-02-10

- Initial Crystal port of `x/exp/teatest/v2`.
- Added `TestModel`, `WaitFor`, and golden output helpers.
- Ported specs and golden testdata.
