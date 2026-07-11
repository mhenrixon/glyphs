# Testing Rules

## TDD Workflow

Follow RED → GREEN → REFACTOR:

1. **RED**: Write a failing test first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve code while keeping tests green

## The test surfaces

glyphs tests with RSpec against fixtures, cheapest first. No Rails app boots — specs
point `Icons.config.base_path` at `spec/fixtures`.

| Surface | Path | Needs | Use for |
|---------|------|-------|---------|
| Icon components | `spec/glyphs/icon_spec.rb`, `kit_spec.rb` | Phlex render + `spec/fixtures/svg` | `svg_for` resolution, variant/library subclasses, HTML output, missing-icon fallback |
| Configuration | `spec/glyphs/configuration_spec.rb` | nothing | `raise_on_missing`, `fallback_icons`, `cache_svgs`, `keep_icons`, `prune_source_globs` |
| Pruning | `spec/glyphs/source_scanner_spec.rb`, `icon_pruner_spec.rb`, `prune_runner_spec.rb`, `prune_report_spec.rb` | `spec/fixtures/source` tree | Prism AST + template scan, dynamic-call harvesting, SVG deletion, `verify!`, report shape |
| RuboCop cops | `spec/rubocop/cop/glyphs/*_spec.rb` | RuboCop `expect_offense`/`expect_correction` | IconResolution, LegacyIconHelper, PreferLibraryComponent offenses + autocorrections |

## Coverage Expectations

- **80% minimum** for all code
- **100%** for the destructive/correctness-critical paths:
  - the icon pruner (never deletes a referenced icon; honors `keep_icons`)
  - `svg_for` resolution (right library/variant path, `raise_on_missing` vs fallback)
  - the source scanner (both static AST calls AND dynamic-call harvesting are caught)
  - cop autocorrection (`expect_correction` produces valid, idempotent output)

## RSpec Conventions

```ruby
subject(:icon) { described_class.new("circle-check", variant: "outline") }

context "when the icon is missing and raise_on_missing is true" do
  it "raises" do
    Glyphs.configuration.raise_on_missing = true
    expect { render described_class.new("does-not-exist") }
      .to raise_error(Glyphs::IconNotFound)
  end
end
```

Cop specs use RuboCop's helpers, not plain matchers:

```ruby
it "flags the legacy helper" do
  expect_offense(<<~RUBY)
    icon("check")
    ^^^^^^^^^^^^^ Glyphs/LegacyIconHelper: Use a library component instead.
  RUBY

  expect_correction(<<~RUBY)
    HeroIcon("check")
  RUBY
end
```

## Pruning specs

- Scanner specs must cover BOTH harvesting paths: static Prism AST calls (`LucideIcon("house")`)
  AND dynamic/interpolated references the text scan recovers. A dynamic reference that
  the AST misses is the regression guard.
- The pruner must be proven to keep, not delete: assert a referenced SVG and a
  `keep_icons` entry both survive, and only truly-unreferenced SVGs are removed.
- `prune_runner_spec` covers `verify!` — the guard that aborts before deleting when the
  source scan looks empty or the fixture tree is misconfigured.
- Drive off the `spec/fixtures/source` tree (components, notifiers, ERB views, the
  intentionally `broken.rb`), never a real app.

## Test Checklist

- [ ] Tests written BEFORE implementation; RED verified
- [ ] `bundle exec rspec` green
- [ ] Cop changes: `expect_offense` AND `expect_correction` both asserted
- [ ] Edge cases: missing icon, unknown variant, `raise_on_missing` on/off, empty prune scan
- [ ] Pruner: referenced + `keep_icons` survive; only unreferenced deleted
- [ ] `bundle exec rubocop lib spec` passes
