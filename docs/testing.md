# Testing

## Running Tests

```bash
# Run all tests
make test
# or
crystal spec -Dpreview_mt -Dexecution_context

# Run specific test file
crystal spec spec/teatest_spec.cr

# Run with update flag (regenerate golden files)
crystal spec -Dpreview_mt -Dexecution_context --update
```

## Test Conventions

- **Test files**: Located in `spec/` directory, named `*_spec.cr`
- **Golden files**: Located in `spec/testdata/` with `.golden` extension
- **Test structure**: Use `Spec` framework with `describe`/`it` blocks
- **Porting tests**: Translate Go tests from `vendor/x/exp/teatest/v2/*_test.go`

## Writing Tests

1. **Golden file tests**: Use `Teatest.require_equal_output` for output comparison
2. **Async tests**: Use `Teatest.wait_for` for waiting on specific output
3. **Test models**: Create simple Term2 models in test files or use fixtures

Example test pattern:
```crystal
describe "Teatest" do
  it "compares output with golden file" do
    tm = Teatest.new_test_model(TestApp.new)
    Teatest.wait_for(tm.output, ->(b : Bytes) { String.new(b).includes?("expected") })
    Teatest.require_equal_output(self, tm.output.to_slice)
    tm.quit
  end
end
```

## Coverage

- **Coverage command**: Not currently configured (TODO: add simplecov)
- **Coverage goal**: Aim for parity with upstream Go test coverage
- **Golden file verification**: All golden files must match upstream Go behavior

<!-- TODO: Add coverage configuration when available -->