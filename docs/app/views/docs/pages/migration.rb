# frozen_string_literal: true

class Views::Docs::Pages::Migration < DocsUI::Page
  title "Migration"
  eyebrow "Guide"

  def lead = "From hand-rolled icon helpers to Glyphs components — mostly autocorrected."

  def content
    before_after
    the_steps
    variants_warning
  end

  private

  def before_after
    DocsUI::Section("What the cop rewrites") do
      DocsUI::Code(<<~RUBY)
        # before                              # after
        _lucide(:house, class: "size-4")      LucideIcon(:house, class: "size-4")
        _hero(:check)                         HeroIcon(:check)
        _heroicon(:check)                     HeroIcon(:check)
        icon("check", library: "lucide")      LucideIcon("check")
        icon("check")                         HeroIcon("check") # DefaultLibraryComponent
      RUBY
    end
  end

  def the_steps
    DocsUI::Section("The steps") do
      md <<~'MD'
        1. Add `gem "glyphs"`; replace `include YourIconHelper` with
           `include Glyphs` in your component base class(es).
        2. Add the RuboCop plugin and cop config (see
           [RuboCop cops](/docs/rubocop-cops)).
        3. **Delete your icon helper first** — otherwise the cop rewrites the
           helper's own internal `icon(...)` delegation.
        4. Run the autocorrect:
      MD
      DocsUI::Code(<<~SHELL, lexer: :shell)
        bundle exec rubocop -A --only Glyphs/LegacyIconHelper,Glyphs/PreferLibraryComponent
      SHELL
      md <<~'MD'
        5. Move your old missing-icon logging into `Glyphs.configure` (see
           [Missing icons](/docs/missing-icons)).

        Custom helper names map via cop config — `Mappings` *replaces* the
        defaults when set:
      MD
      DocsUI::Code(<<~YAML, lexer: :yaml, filename: ".rubocop.yml")
        Glyphs/LegacyIconHelper:
          Mappings:
            _custom: CustomIcon
          DefaultLibraryComponent: HeroIcon
      YAML
    end
  end

  def variants_warning
    DocsUI::Section("Audit forced variants first") do
      md <<~'MD'
        If your helpers hardcoded variants (`icon(name, variant: "light", ...)`
        inside the helper body), confirm your rails_icons config reproduces
        them as *default variants* before autocorrecting — the components pass
        `variant: nil` and let the `icons` gem resolve the default. A drifted
        default silently changes which SVG renders. `Glyphs/IconResolution`
        validates against the default-variant directory, so a wrong default
        usually surfaces as a wall of "not found" offenses.
      MD
    end
  end
end
