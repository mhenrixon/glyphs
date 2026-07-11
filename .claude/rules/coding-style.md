# Coding Style Rules

## File Organization

**MANY SMALL FILES > FEW LARGE FILES**

- High cohesion, low coupling
- 200-400 lines typical
- 800 lines maximum per file
- Extract complex logic to dedicated classes
- Organize by concern (icon components, config, scanner/pruner, rubocop cops, rake wiring)

## Ruby Style

Lint with **RuboCop** (`bundle exec rubocop lib spec`). RuboCop owns formatting —
don't hand-fight it; run `rubocop -A` and review.

### Classes & Methods

```ruby
# Good: small, focused methods
def render_svg(name:, library:, variant:, attributes:)
  build_svg(name:, library:, variant:, attributes:)
rescue Icons::IconNotFound => e
  handle_missing_icon(e, name:, library:, variant:, attributes:)
end

# Bad: one giant method doing lookup, caching, missing-icon policy, and fallback
```

### One tiny subclass per library

```ruby
# Good: the subclass declares its library; the base Icon does the work
class LucideIcon < Icon
  LIBRARY = :lucide
end

# Bad: reimplementing resolution/rendering in each library component
```

### Resolve through `Glyphs.svg_for`, never bypass it

```ruby
# Good: one resolution path (missing-icon policy + cache live here)
Glyphs.svg_for(name:, library:, variant:, attributes:)

# Bad: calling Icons::Icon.new(...).svg directly from a component
#      (skips raise_on_missing, on_missing_icon, fallback_icons, cache_svgs)
```

### Missing-icon policy is configured, not hardcoded

```ruby
# Good: honor the configured policy — raise / instrument / fall back
raise error if configuration.raise_on_missing
configuration.on_missing_icon&.call(error, name:, library:, variant:)
fallback = configuration.fallback_icons[library.to_sym]

# Bad: swallow Icons::IconNotFound and render nothing, or always raise
```

### Dynamic references are skipped statically, kept via config

```ruby
# Good: the scanner harvests only statically-known names; dynamic ones are
# covered by keep_icons (a flat list or { library => [names/globs] })
config.keep_icons = { lucide: ["chevron-*"], phosphor: %w[question] }

# Bad: assume every icon has a literal call site, then prune ones built at
#      runtime (e.g. LucideIcon(some_var)) and 404 in production
```

### Fail soft when scanning, not the whole run

```ruby
# Good: a file that won't parse warns and is skipped
begin
  Prism.parse_file(path)
rescue => e
  warn "glyphs: skipping #{path} (#{e.message})"
end

# Bad: one malformed template aborts the entire prune scan
```

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Methods are small (<30 lines ideal, <50 max)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Components resolve through `Glyphs.svg_for` — no direct `Icons::Icon` calls
- [ ] Missing-icon handling honors the configured policy (raise / instrument / fallback)
- [ ] The pruner never deletes `keep_icons` / `fallback_icons`; dynamic names are keep-listed
- [ ] `bundle exec rubocop lib spec` passes
