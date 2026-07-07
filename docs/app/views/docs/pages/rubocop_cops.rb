# frozen_string_literal: true

class Views::Docs::Pages::RubocopCops < DocsUI::Page
  title "RuboCop cops"
  eyebrow "Reference"

  def lead = "Icon-name validation and legacy-helper autocorrection, shipped with the gem."

  def content
    setup
    legacy_icon_helper
    icon_resolution
    prefer_library_component
  end

  private

  def setup
    DocsUI::Section("Setup", description: "A lint_roller plugin — RuboCop >= 1.72.") do
      DocsUI::Code(<<~YAML, lexer: :yaml, filename: ".rubocop.yml")
        plugins:
          - glyphs

        Glyphs/LegacyIconHelper:
          Include:
            - app/**/*.rb
            - spec/**/*.rb
        Glyphs/IconResolution:
          Include:
            - app/**/*.rb
          IconsPath: app/assets/svg/icons
      YAML
      md <<~'MD'
        RuboCop never becomes a runtime dependency of your app — the plugin
        constant loads lazily, only inside a RuboCop process. Classic
        `require: [glyphs/rubocop]` also works, but then you enable the cops
        yourself.
      MD
    end
  end

  def legacy_icon_helper
    DocsUI::Section("Glyphs/LegacyIconHelper") do
      md <<~'MD'
        Rewrites legacy helper calls to Glyphs components — `_lucide`,
        `_phosphor`, `_hero`, `_heroicon`, `_tabler` and bare `icon()` (with
        `library:`/`from:` literal extraction, or `DefaultLibraryComponent`
        when absent). Dynamic or unmapped libraries are flagged without
        autocorrection.

        | Option | Default | Meaning |
        |---|---|---|
        | `Mappings` | the five helpers above | helper → component; **replaces** the defaults when set |
        | `DefaultLibraryComponent` | `HeroIcon` | target for bare `icon()` calls |
        | `LibraryComponents` | all 13 libraries | `library:` literal → component |
      MD
    end
  end

  def icon_resolution
    DocsUI::Section("Glyphs/IconResolution") do
      md <<~'MD'
        Validates statically-known icon names against your synced SVG
        directories — variant-aware (a literal `variant:` selects the directory
        it validates against), with fuzzy typo suggestions
        (Damerau–Levenshtein + part scoring), autocorrection for unambiguous
        matches and the Lucide v1 renames, and detection of raw
        `iconify <library>--<name>` class strings (single-class `span`s are
        autocorrected to component calls). Legacy helper calls are validated
        too, so the cop protects you before *and* after migration.

        | Option | Default | Meaning |
        |---|---|---|
        | `IconsPath` | `app/assets/svg/icons` | root of the synced SVG tree |
        | `Libraries` | lucide/phosphor/heroicons/tabler/sidekickicons | component → `{ Dir:, DefaultVariant: }`; **merges** over the defaults |

        Dynamic names, dynamic variants, unknown components, and a missing
        `IconsPath` are all skipped silently — the cop never guesses.
      MD
    end
  end

  def prefer_library_component
    DocsUI::Section("Glyphs/PreferLibraryComponent") do
      md <<~'MD'
        Rewrites generic `Icon(name, library: <literal>)` kit calls to the
        library-specific component and drops the `library:` pair. Dynamic
        libraries are flagged without autocorrection.
      MD
      DocsUI::Code(<<~RUBY)
        Icon(:house, library: :lucide) # => LucideIcon(:house)
      RUBY
    end
  end
end
