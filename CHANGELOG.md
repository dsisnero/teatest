# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
