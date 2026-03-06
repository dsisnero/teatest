---
upstream_repo: "https://github.com/charmbracelet/ansi"
pinned_revision: "{{pinned_revision}}"
import_mode: "submodule"
upstream_submodule_path: "vendor/x/exp/teatest/v2"
---

# Porting Parity

## Upstream Source of Truth

- Repository: `https://github.com/charmbracelet/ansi`
- Pinned revision: `{{pinned_revision}}` (check git submodule status)
- Import mode: `submodule`
- Upstream path: `vendor/x/exp/teatest/v2`

## Parity Scope

| Upstream Module/Path | Crystal Target | Status | Notes |
|----------------------|----------------|--------|-------|
| `teatest.go` | `src/teatest.cr` | Ported | Main implementation |
| `teatest_test.go` | `spec/teatest_spec.cr` | Partial | Tests being ported |
| `app_test.go` | `spec/app_spec.cr` | Partial | App tests being ported |
| `send_test.go` | `spec/send_spec.cr` | Partial | Send tests being ported |
| `testdata/` | `spec/testdata/` | Copied | Golden files copied from upstream |

## Behavior Checklist

- [ ] Public API surface mapped
- [ ] Constants and types ported
- [ ] Error semantics matched
- [ ] Edge cases mirrored
- [ ] Fixtures/goldens verified

## Test Parity

| Upstream Test/Fixture | Crystal Spec | Status | Notes |
|------------------------|--------------|--------|-------|
| `TestRequireEqualOutput` | `spec/teatest_spec.cr` | TODO | Basic golden file test |
| `TestApp` | `spec/app_spec.cr` | TODO | Simple app testing |
| `TestAppSendToOtherProgram` | `spec/send_spec.cr` | TODO | Send functionality |

## Known Deviations

<!-- TODO: List intentional deviations and why they are unavoidable. -->

## Verification Commands

```bash
# Verify upstream Go tests pass
cd vendor/x/exp/teatest && go test ./v2

# Run Crystal quality gates
crystal tool format --check src spec
ameba src spec
crystal spec -Dpreview_mt -Dexecution_context
```