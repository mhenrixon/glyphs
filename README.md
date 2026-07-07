# Glyphs

Phlex icon components for every [rails_icons](https://github.com/rails-designer/rails_icons) library —
plus bundled RuboCop cops that validate icon names at lint time and autocorrect legacy icon helpers.

```ruby
class ApplicationComponent < Phlex::HTML
  include Glyphs
end

LucideIcon(:house, class: "size-4")
PhosphorIcon("lock", variant: :bold)
HeroIcon(:check, class: "size-5 text-success")
```

## Installation

```ruby
# Gemfile
gem "glyphs"
```

Glyphs renders the SVG files that rails_icons syncs into your app. If you haven't already:

```bash
rails generate rails_icons:install --libraries=lucide heroicons
rails generate rails_icons:sync --libraries=lucide heroicons
```

Outside Rails, configure the [icons](https://rubygems.org/gems/icons) gem directly:

```ruby
Icons.configure do |config|
  config.base_path = File.expand_path(__dir__)
  config.icons_path = "svg/icons"
end
```

## Components

`include Glyphs` (a `Phlex::Kit`) into your component base class and call icons as capitalized methods:

| Component | rails_icons library |
|---|---|
| `LucideIcon` | lucide |
| `PhosphorIcon` | phosphor |
| `HeroIcon` | heroicons |
| `TablerIcon` | tabler |
| `FeatherIcon` | feather |
| `BoxIcon` | boxicons |
| `FlagIcon` | flags |
| `HugeIcon` | hugeicons |
| `LinearIcon` | linear |
| `RadixIcon` | radix |
| `SidekickIcon` | sidekickicons |
| `WeatherIcon` | weather |
| `AnimatedIcon` | animated (bundled spinners: `faded-spinner`, `bouncing-dots`, ...) |

Names can be symbols or strings; underscores are dasherized (`:circle_check` → `circle-check.svg`).
`variant:` selects the library variant (default comes from your rails_icons/icons configuration);
every other keyword (`class:`, `data:`, `stroke_width:`, ...) is forwarded onto the `<svg>` tag.

The generic component requires an explicit library:

```ruby
Icon(:house, library: :lucide) # flagged by Glyphs/PreferLibraryComponent, prefer LucideIcon(:house)
```

Custom libraries get first-class components too:

```ruby
Glyphs.register_library(:brand, component: :BrandIcon)
BrandIcon(:logo)
```

(The SVG location for a custom library is configured through rails_icons/icons custom-library config.)

## Missing-icon policy

```ruby
# config/initializers/glyphs.rb
Glyphs.configure do |config|
  # Re-raise Icons::IconNotFound? Default: true locally (dev/test), never blind in production.
  config.raise_on_missing_icon = -> { Rails.env.local? }

  # Instrumentation hook, called before the fallback renders.
  config.on_missing_icon = lambda do |error, name:, library:, variant:|
    Rails.logger.error("Icon missing: #{library}/#{variant}/#{name} (#{error.message})")
  end

  # Rendered instead of the missing icon (per library). nil/absent => re-raise.
  config.fallback_icons = {
    lucide: "circle-question-mark",
    phosphor: "question",
    heroicons: "question-mark-circle"
  }

  # Memoize rendered SVG strings per [library, variant, name, attributes]. Default: true.
  # Note: fallback renders are cached under the original name, so on_missing_icon
  # fires once per process per missing icon rather than on every render.
  config.cache_svgs = true
end
```

## RuboCop cops

Add the plugin (RuboCop >= 1.72):

```yaml
# .rubocop.yml
plugins:
  - glyphs
```

(Classic `require: [glyphs/rubocop]` also works, but you must enable the cops yourself.)

### Glyphs/LegacyIconHelper

Autocorrects legacy helper calls to Glyphs components:

```ruby
_lucide(:house, class: "size-4")   # => LucideIcon(:house, class: "size-4")
_heroicon(:check)                  # => HeroIcon(:check)
icon("check", library: "lucide")   # => LucideIcon("check")
icon("check")                      # => HeroIcon("check")  (DefaultLibraryComponent)
```

```yaml
Glyphs/LegacyIconHelper:
  Include:
    - app/**/*.rb
  DefaultLibraryComponent: HeroIcon
  # Mappings replaces the built-in defaults (_lucide/_phosphor/_hero/_heroicon/_tabler):
  # Mappings:
  #   _custom: CustomIcon
```

### Glyphs/IconResolution

Validates statically-known icon names against your synced SVG directories, honors literal
`variant:` keywords, suggests close matches (with autocorrect for unambiguous typos and the
Lucide v1 renames), and flags raw `iconify` class strings:

```ruby
LucideIcon(:alert_triangle)                 # => corrected to LucideIcon(:triangle_alert)
span(class: "iconify lucide--house size-4") # => corrected to LucideIcon(:house, class: "size-4")
```

```yaml
Glyphs/IconResolution:
  Include:
    - app/**/*.rb
  IconsPath: app/assets/svg/icons
  # Libraries merges over the built-in defaults (component => Dir/DefaultVariant):
  Libraries:
    PhosphorIcon: { Dir: phosphor, DefaultVariant: regular }
```

### Glyphs/PreferLibraryComponent

```ruby
Icon(:house, library: :lucide) # => LucideIcon(:house)
```

## Migrating an app off icon helpers

1. Add `gem "glyphs"`, `include Glyphs` where the helpers used to be included.
2. Add the plugin and cop config above to `.rubocop.yml`.
3. Delete your local icon helper, then run:

```bash
bundle exec rubocop -A --only Glyphs/LegacyIconHelper,Glyphs/PreferLibraryComponent
```

4. Wire your old missing-icon logging into `Glyphs.configure` (see above).

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT — see [LICENSE.txt](LICENSE.txt).
