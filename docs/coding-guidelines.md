# Coding Guidelines

## Code Style

- **Formatter**: `crystal tool format` (enforced via `make format`)
- **Linter**: `ameba` (enforced via `make lint`)
- **Line length**: Follow Crystal formatter defaults
- **Indentation**: 2 spaces (Crystal standard)

## Error Handling

- **Porting approach**: Match Go error messages and semantics exactly
- **Error types**: Use Crystal exception hierarchy but preserve Go error meanings
- **Error context**: Include relevant context from Go source when porting

## Naming Conventions

- **Files**: Crystal files use `.cr` extension, test files end with `_spec.cr`
- **Classes/Modules**: CamelCase (e.g., `Teatest`, `TestModel`)
- **Methods**: snake_case (e.g., `new_test_model`, `wait_for`)
- **Variables**: snake_case
- **Constants**: SCREAMING_SNAKE_CASE

## Documentation

- **Public API**: Document all public methods with yardoc format
- **Porting notes**: Add comments referencing upstream Go source when behavior is ported
- **TODOs**: Use `# TODO: ` for incomplete porting work

<!-- TODO: Add examples from the codebase -->