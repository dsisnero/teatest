# Resuming Work

First read in a new session. It should take a few minutes to get back to a
known-good state.

## 1. Read where we are

- [plans/parity.md](../plans/parity.md) — start at the **Where we are** block.
  It names the current focus, the ordered "Next up" list, per-area status,
  gotchas, the last commit, and the current gate results. Do not re-derive
  state from git history.
- [plans/inventory/go_port_inventory.tsv](../plans/inventory/go_port_inventory.tsv)
  — the per-symbol ledger (status + `crystal_refs`), keyed to the `# baseline=`
  comment at the top. Run `make inventory` before trusting it. To see what is
  left inside the current chunk:

  ```bash
  awk -F '\t' '!/^#/ && NF {print $3}' \
    plans/inventory/go_port_inventory.tsv | sort | uniq -c
  ```

## 2. Confirm the working tree

```bash
git log --oneline -10
git status
```

The last commit should be the previous feature, committed atomically. If the
tree is dirty, finish or stash before starting. Pending `spec/testdata/*.golden.new`
files are review artifacts and are gitignored.

## 3. Confirm a clean baseline

```bash
make format
make lint
make test
make inventory
```

Format, lint, and inventory must pass before changing anything. `make test`
passes 10/10 runs; `spec/send_spec.cr` keeps both programs alive 50ms past a
renderer tick so the startup capability-query flush cannot land on different
sides of shutdown in the two captures. If a send-only failure reappears where
the outputs differ solely in the position of `ESC[?2026$p ESC[?2027$p`, that
settle was lost — see
[lib_issues/bubbletea.5.md](../lib_issues/bubbletea.5.md). Do not normalize the
fixture to hide it.

`make inventory` forwards to the installed cross-language parity skill and
prints `PARITY_DISCOVERY_BACKEND=chiasmus-tree-sitter`. It also validates
`crystal_refs` symbols against `src` (`PORT_CRYSTAL_SOURCE=src`), so a renamed
method fails the gate. The ledger uses the tree-sitter vocabulary; if the
backend line says `regex`, the Chiasmus toolchain is missing and the run is not
the gate you think it is.

Optional strict preflight (checks the skill wrappers are executable and resolves
the toolchain):

```bash
PARITY_SKILL_DIR="${HOME}/.agents/skills/crystal_forge/skills/cross-language-crystal-parity"
"${PARITY_SKILL_DIR}/scripts/verify_skill_install.sh" . go tree-sitter
```

## 4. Pick the next feature

Take the first unchecked item in **Next up** (or the next `[ ]` item in the
current phase). For each feature:

1. Read the upstream source under `vendor/x/exp/teatest/v2` and the nearest
   upstream test.
2. Port the test first (red → green); never weaken assertions.
3. Satisfy the **Definition of done** in [AGENTS.md](../AGENTS.md): API, tests,
   gates, inventory rows, `plans/parity.md` status + **Where we are** refresh,
   and divergences.
4. Commit atomically with the `port: ...` message format from
   [AGENTS.md](../AGENTS.md).

## Environment notes

This checkout lives on an external volume where macOS writes AppleDouble `._*`
sidecars next to edited files. They confuse `find`/shell tooling and can add
`._foo_spec.cr` files to spec discovery, so `make format`, `make lint`, and
`make test` depend on the `sidecars` target and delete them first. If a git
pack operation reports `non-monotonic index .../._pack-*.idx`, clear the
sidecars in git metadata with:

```bash
find .git -name '._*' -delete
```
