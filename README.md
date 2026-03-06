<p align="center">
  <strong>Crystal port of Go teatest library</strong><br>
  Test Bubbletea programs easily, including golden files
</p>

<p align="center">
  <a href="docs/architecture.md">Architecture</a> &middot;
  <a href="docs/development.md">Development</a> &middot;
  <a href="docs/coding-guidelines.md">Guidelines</a> &middot;
  <a href="docs/testing.md">Testing</a> &middot;
  <a href="docs/pr-workflow.md">PR Workflow</a> &middot;
  <a href="docs/porting-parity.md">Porting Parity</a>
</p>

---

Test helpers for Term2 programs. This is a Crystal port of the Go `x/exp/teatest/v2` package from charmbracelet/ansi.

---

## Quick Start

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  teatest:
    github: dsisnero/teatest
```

2. Run `shards install`

3. Use in your tests:

```crystal
require "teatest"
require "term2"

class Counter
  include Term2::Model

  def initialize(@n : Int32 = 0)
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.code == Ultraviolet::KeyEnter
        return {self, nil}
      end
    end
    {self, nil}
  end

  def view : String
    "count=#{@n}\n"
  end
end

tm = Teatest.new_test_model(Counter.new)
Teatest.wait_for(tm.output, ->(b : Bytes) { String.new(b).includes?("count=") })
tm.quit
```

## Features

- **Golden file testing**: Compare output with expected golden files
- **Async testing**: Wait for specific output patterns
- **Term2 integration**: Test Bubble Tea applications
- **Go parity**: Behavior matches upstream Go `x/exp/teatest/v2`
- **ANSI handling**: Proper terminal escape sequence support

## Development

```bash
# Install dependencies
make install

# Run tests
make test

# Check code quality
make format
make lint
```

See [Development Guide](docs/development.md) for full setup instructions.

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design and data flow |
| [Development](docs/development.md) | Setup and daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Code style and conventions |
| [Testing](docs/testing.md) | Test commands and patterns |
| [PR Workflow](docs/pr-workflow.md) | Commits, PRs, and review process |
| [Porting Parity](docs/porting-parity.md) | Upstream source mapping and behavior parity |

## Contributing

1. Create an issue: `/forge-create-issue`
2. Implement: `/forge-implement-issue <number>`
3. Self-review: `/forge-reflect-pr`
4. Address feedback: `/forge-address-pr-feedback`
5. Update changelog: `/forge-update-changelog`