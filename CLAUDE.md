# teatest

> **How to resume:** read `plans/parity.md` first and use its **Where we are**
> block (current focus + ordered "Next up"), then run `make lint` and
> `make test`. Details: [docs/resuming.md](docs/resuming.md). Do not re-derive
> state from git.

Crystal port of Go `x/exp/teatest/v2` (Go) from
[charmbracelet/x](https://github.com/charmbracelet/x), vendored at
`vendor/x/exp/teatest/v2` (commit `bb9a970`, submodule describe
`powernap/v0.1.5-52-gbb9a970`). Test helpers for Bubble Tea Crystal programs,
including golden-output comparison.

## Commands

```bash
make install          # shards install
make update           # shards update
make format           # crystal tool format --check src spec
make lint             # ameba src spec
make test             # crystal spec
make inventory        # parity ledger drift check (forwards to installed skill)
make parity-refresh   # regenerate source/test manifests on an upstream bump
make clean            # strip AppleDouble sidecars, clear ./temp/*
```

## Docs

- [Resuming work](docs/resuming.md)
- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Coding Guidelines](docs/coding-guidelines.md)
- [Testing](docs/testing.md)
- [PR Workflow](docs/pr-workflow.md)
- [Porting Parity](docs/porting-parity.md)

## Public API

```crystal
# Test model lifecycle
tm = Teatest.new_test_model(model, [Teatest.with_initial_term_size(80, 24)])
tm.send(msg)
tm.type("text")
tm.output          # IO reader for current output
tm.final_output    # wait for completion, get full output
tm.final_model     # wait for completion, get final model
tm.wait_finished   # wait for program exit
tm.quit

# Assertions
Teatest.wait_for(output_io, ->(b : Bytes) { String.new(b).includes?("done") },
  [Teatest.with_duration(1.second)])
Teatest.require_equal_output("TestName", output_bytes)

# Snapshot management (Crystal-only extension)
Teatest.show_snapshot(path)            # read golden file
Teatest.test_and_review!("crystal spec") # run specs then review
Teatest.review!                        # list pending snapshots
```

## Principles

1. Upstream behavior is the source of truth; `vendor/x/exp/teatest/v2` wins
   over local preference.
2. Port behavior, not style. Use Crystal idioms without changing semantics.
3. Port upstream tests early and never weaken assertions.
4. Treat the non-`v2` files under `vendor/x/exp/teatest/` as the v1 baseline;
   never pull parity logic from them.
5. Track parity in `plans/parity.md` and `plans/inventory/`.
6. Commit one completed feature at a time.

## Parity tooling

The active cross-language parity skill is
`/Users/dominic/.agents/skills/crystal_forge/skills/cross-language-crystal-parity`
(override with `PARITY_SKILL_DIR`). `make inventory` invokes the installed
skill's current scripts through the forwarding wrappers in `scripts/`; the repo
must not carry a copied Ruby implementation. Updating the installed skill does
not update repository instructions — check the forwarded target when inventory
behavior changes.

The curated ledger (`plans/inventory/go_port_inventory.tsv`) uses the `regex`
discovery vocabulary, so the gate pins `PORT_PARSER=regex` (`PARITY_PARSER` in
the `Makefile`). `make inventory` also sets `PORT_CRYSTAL_SOURCE=src`, so
`crystal_refs` entries written as `path::kind::name` are validated against
Crystal discovery; use that form for new refs (file-only refs are reserved for
Crystal `alias` types, which the regex vocabulary does not discover). Keep the
parser mode until the tree-sitter migration in `plans/parity.md` is reviewed: a
requested parser mode does not prove which extractor ran, so confirm
`PARITY_DISCOVERY_BACKEND` in the gate output.

```bash
PARITY_SKILL_DIR="${PARITY_SKILL_DIR:-$HOME/.agents/skills/crystal_forge/skills/cross-language-crystal-parity}"
"${PARITY_SKILL_DIR}/scripts/verify_skill_install.sh" . go regex
PORT_PARSER=regex make inventory
```

Curated kinds for Go are gated separately:

```bash
python3 "${PARITY_SKILL_DIR}/scripts/check_kind_vocabulary.py" \
  --scan go="$(pwd)/vendor/x/exp/teatest/v2"
```

## Session continuity (read this first)

`plans/parity.md` is the single source of truth for where we are. At the start
of every session:

1. Read `plans/parity.md` and use its **Where we are** block to find the current
   focus, the ordered "Next up" list, and per-area status. Do not re-derive
   state from git history.
2. Skim `git log --oneline -10` and `git status` to confirm the working tree.
3. Run `make format`, `make lint`, `make test`, and `make inventory` before
   changes.

See [docs/resuming.md](docs/resuming.md) for the full resume checklist.

### Keeping `plans/parity.md` resumable

- Start with a **Where we are** block (`Current focus`, `Next up`, status by
  area, gotchas, last commit, gate results). Keep it accurate after every
  feature.
- Work items are feature-sized (roughly one branch/commit). Per-symbol state
  lives in `plans/inventory/go_port_inventory.tsv`, not in the plan.
- The ledger is a current-state artifact of the pinned baseline (see its
  leading `# baseline=` comment). Re-base it when the target release changes;
  never append across versions. Per-release history belongs in
  `plans/inventory/v<NN>_delta_triage.tsv`, one file per release, never edited
  afterwards.
- If the plan grows too large, split it into `plans/<area>.md` files, link each
  from `plans/parity.md`, and mark each split file complete/in-progress plus
  the file being worked on next.

### Definition of done for every feature (required)

A feature is complete only when all of the following are true, and all of it
must be committed as **one** atomic commit before starting the next feature:

1. the API surface is implemented;
2. upstream tests (or equivalent characterization specs) exist and pass;
3. gates pass: `make format`, `make lint`, `make test`, and `make inventory`;
4. parity inventory rows for the feature are updated in
   `plans/inventory/go_port_inventory.tsv` and `make inventory` passes — it
   checks every row against the pinned tree *and* that each `crystal_refs` file
   still exists;
5. `plans/parity.md` status is updated and the **Where we are** block refreshed
   (current focus + next up);
6. any intentional divergence is documented in `plans/parity.md`,
   `divergence.md`, and/or the commit message.

### Commit message

Porting work starts with `port:` and a one-line feature name, then bullets for
what changed, then the upstream revision (`charmbracelet/x bb9a970`). Include
new/changed files, divergences, and gate results so a new session can resume
from the commit alone. Non-porting maintenance keeps the repository convention
`<type>(<scope>): <description>` (feat, fix, docs, refactor, test, chore,
perf) — see [docs/pr-workflow.md](docs/pr-workflow.md).

## Debugging

When tests fail:

1. Check golden drift: compare `spec/testdata/*.golden` with pending
   `*.golden.new` files.
2. Verify upstream behavior: run Go tests in `vendor/x/exp/teatest/v2`.
3. Check ANSI/terminal-sequence handling: several fixtures depend on control
   codes and output ordering.
4. Inspect `./temp/` for test artifacts.

Common issues:

- ANSI sequence mismatches between Go and Crystal implementations.
- Timing differences in asynchronous test operations.
- File path differences between Go and Crystal test runners.

## Conventions

- **File naming**: Crystal files use `.cr`; test files end with `_spec.cr`.
- **Test data**: golden files in `spec/testdata/` with `.golden`; pending
  review output uses `.golden.new` and is gitignored.
- **Porting approach**: translate Go tests to Crystal specs while preserving
  exact behavior.
- **Error handling**: match Go error messages and semantics where possible.
- **Type naming**: CamelCase for classes/modules; snake_case for methods.
- **Tooling hygiene**: parity scripts forward to the installed skill; never
  copy its Ruby implementation into `scripts/`.
- **Dependency bugs**: never patch `lib/` in place. Write a numbered report in
  `shards_issues/<shard>.<upstream-issue-number>.md` (for example
  `shards_issues/bubbletea.5.md`) with summary, environment, reproduction,
  actual/expected, root cause, and proposed fix.
