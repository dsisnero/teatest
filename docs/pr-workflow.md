# PR Workflow

## Commit Conventions

Format: `<type>(<scope>): <description>`

Types: feat, fix, docs, refactor, test, chore, perf

### Examples

- `feat(teatest): add send_to_other_program support`
- `fix(golden): handle ANSI escape sequences in output comparison`
- `docs(readme): update installation instructions for Crystal 1.19+`
- `test(app): port TestAppSendToOtherProgram from Go upstream`
- `chore(deps): update bubbletea.cr to v0.5.0`

## Branch Naming

Format: `<type>/<issue-number>-<short-kebab-description>`

### Examples

- `feat/42-add-send-support`
- `fix/55-ansi-escape-handling`
- `docs/12-update-readme-install`
- `test/23-port-app-tests`

## PR Checklist

- [ ] Code follows project guidelines (see [Coding Guidelines](coding-guidelines.md))
- [ ] Tests added/updated (see [Testing](testing.md))
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated for user-facing changes
- [ ] Lint/format checks pass (`make format && make lint`)
- [ ] All tests pass (`make test`)
- [ ] Upstream parity verified (Go tests pass in `vendor/x/exp/teatest/v2`)

## Review Process

1. **Self-review**: Run `/forge-reflect-pr` before requesting review
2. **Peer review**: Request review from maintainers
3. **Address feedback**: Use `/forge-address-pr-feedback` to systematically address comments
4. **CI verification**: Ensure all checks pass
5. **Merge**: Squash or merge based on project conventions
6. **Changelog**: Update CHANGELOG.md for user-facing changes