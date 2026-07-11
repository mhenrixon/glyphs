---
model: opus
description: "Use when implementing any feature or fixing any bug — enforces RED-GREEN-REFACTOR: write failing test first, implement minimum code to pass, then refactor."
---

# TDD Command

Enforce test-driven development with RED → GREEN → REFACTOR.

## The TDD Cycle

```text
RED:      Write a failing test (it MUST fail first)
GREEN:    Write MINIMAL code to pass (nothing more)
REFACTOR: Improve code while keeping tests green
REPEAT:   Next scenario
```

## When to Use

- Adding or changing an icon component (a new library subclass, `svg_for` resolution)
- Extending the source scanner (a new AST node, dynamic-call harvesting, template scan)
- Changing the pruner, prune runner, or the `verify!` safety gate
- Adding or changing a RuboCop cop
- Fixing a bug (write the reproducing test FIRST)

## Workflow

### Step 1: Write Failing Tests (RED)

Pick the cheapest layer that proves the behavior:

```ruby
# Configuration / resolution: the DSL and config gate
RSpec.describe Glyphs::Configuration do
  it "defaults raise_on_missing to false" do
    expect(described_class.new.raise_on_missing).to be(false)
  end
end

# Component: the rendered SVG
RSpec.describe Glyphs::LucideIcon do
  it "renders the SVG for a known icon" do
    expect(render(described_class.new(:home))).to include("<svg")
  end
end

# Scanner: what references get harvested from source
RSpec.describe Glyphs::SourceScanner do
  it "harvests a dynamic library call" do
    expect(scan("lucide_icon(name)")).to include("lucide")
  end
end

# Cop: the offense and its autocorrection
RSpec.describe RuboCop::Cop::Glyphs::PreferLibraryComponent do
  it "flags the legacy helper" do
    expect_offense(<<~RUBY)
      icon("lucide", "home")
      ^^^^^^^^^^^^^^^^^^^^^^^ Glyphs/PreferLibraryComponent: ...
    RUBY
  end
end
```

### Step 2: Run — Verify FAIL

```bash
bundle exec rspec <spec_file>
# FAIL — confirms the test runs, tests the right thing, and the code doesn't already exist
```

### Step 3: Implement Minimal Code (GREEN)

### Step 4: Run — Verify PASS

```bash
bundle exec rspec <spec_file>
# N examples, 0 failures
```

### Step 5: Refactor

Improve while staying green: extract methods, improve names, reduce duplication.

### Step 6: Run Full Suite + Lint

```bash
bundle exec rspec
bundle exec rubocop lib spec
```

## Coverage Expectations

| Code | Minimum |
|------|---------|
| All code | 80% |
| the source scanner (AST nodes, dynamic-call harvesting, template text scan) | 100% |
| the pruner `verify!` gate (never delete a referenced or kept icon) | 100% |
| `svg_for` resolution (missing icon: raise vs fallback per config) | 100% |

## Destructive paths: test BOTH sides

The pruner deletes files — any change touching deletion MUST have specs for:
- **referenced / kept icon** — the icon is retained; `verify!` refuses to delete it
- **unreferenced icon** — it is pruned, and the report counts it
  (drive `keep_icons` and `prune_source_globs` config so the retention gate is a
  regression guard against ever deleting an in-use SVG)

## Best Practices

**DO:** test FIRST; verify RED; minimal GREEN; refactor green; drive scanner specs
off real fixture source in `spec/fixtures`; use `expect_offense`/`expect_correction`
for cops; point `Icons.config.base_path` at the fixtures.

**DON'T:** implement before testing; test implementation details; assert on the whole
rendered SVG string when one attribute is the point; skip the retention path when
touching the pruner.

## Checklist

- [ ] Tests written BEFORE implementation; RED verified
- [ ] Minimal GREEN; refactored green
- [ ] Coverage meets the bar (100% on scanner + the `verify!` gate)
- [ ] Edge + error paths covered (missing icon, empty scan, no matches)
- [ ] Pruner changes: referenced-kept AND unreferenced-pruned both tested
- [ ] `bundle exec rubocop lib spec` passes
