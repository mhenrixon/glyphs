# frozen_string_literal: true

class Views::Docs::Pages::QuickStart < DocsUI::Page
  title "Quick start"
  eyebrow "Getting started"

  def lead = "Render icons from any library, pick variants, pass attributes."

  def content
    render_icons
    names
    variants
    attributes
    generic_component
  end

  private

  def render_icons
    DocsUI::Section("Render an icon", description: "One capitalized method per library.") do
      DocsUI::Code(<<~RUBY)
        LucideIcon(:house)
        HeroIcon(:check)
        PhosphorIcon(:lock)
        TablerIcon(:brand_github)
        AnimatedIcon("faded-spinner")
      RUBY
      md <<~'MD'
        Each call renders the SVG file inline — with the library's configured
        default CSS classes and attributes from your rails_icons initializer.
      MD
    end
  end

  def names
    DocsUI::Section("Names") do
      md <<~'MD'
        Names can be symbols or strings; underscores are dasherized, so
        `:circle_check` and `"circle-check"` both resolve to `circle-check.svg`.
        Dynamic names are fine too — `LucideIcon(status_icon)` — the RuboCop
        validation simply skips what it can't see statically.
      MD
    end
  end

  def variants
    DocsUI::Section("Variants") do
      md <<~'MD'
        `variant:` selects the library variant directory. Without it, the
        library's default variant from your rails_icons/icons configuration
        applies (heroicons → `outline`, phosphor → `regular`, ...).
      MD
      DocsUI::Code(<<~RUBY)
        HeroIcon(:check)                    # heroicons/outline/check.svg
        HeroIcon(:check, variant: :solid)   # heroicons/solid/check.svg
        PhosphorIcon(:lock, variant: :bold) # phosphor/bold/lock.svg
      RUBY
    end
  end

  def attributes
    DocsUI::Section("Attributes") do
      md <<~'MD'
        Every other keyword is forwarded onto the `<svg>` tag — `class:`,
        `data:`, `stroke_width:`, anything:
      MD
      DocsUI::Code(<<~RUBY)
        LucideIcon(:house, class: "size-4 text-primary")
        LucideIcon(:zap, stroke_width: 2, data: { controller: "sparkle" })
      RUBY
    end
  end

  def generic_component
    DocsUI::Section("The generic component") do
      md <<~'MD'
        `Icon(...)` is the abstract base — it requires an explicit `library:`
        and raises `ArgumentError` without one. Prefer the library components;
        the `Glyphs/PreferLibraryComponent` cop autocorrects literal-library
        calls for you.
      MD
      DocsUI::Code(<<~RUBY)
        Icon(:house, library: :lucide) # works, but the cop rewrites it to:
        LucideIcon(:house)
      RUBY
    end
  end
end
