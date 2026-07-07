# frozen_string_literal: true

class Views::Docs::Pages::CustomLibraries < DocsUI::Page
  title "Custom libraries"
  eyebrow "Guide"

  def lead = "First-class components for your own icon sets."

  def content
    register
    svg_location
  end

  private

  def register
    DocsUI::Section("Register a library") do
      DocsUI::Code(<<~RUBY, filename: "config/initializers/glyphs.rb")
        Glyphs.register_library(:brand, component: :BrandIcon)
      RUBY
      DocsUI::Code(<<~RUBY)
        BrandIcon(:logo, class: "size-6")
      RUBY
      md <<~'MD'
        `register_library` defines `Glyphs::BrandIcon < Glyphs::Icon` and the
        kit picks the constant up automatically — the `BrandIcon(...)` method
        exists everywhere `Glyphs` is included. Registration is idempotent;
        re-registering the same component for a *different* library raises.
      MD
    end
  end

  def svg_location
    DocsUI::Section("Where the SVGs come from") do
      md <<~'MD'
        glyphs resolves files through the `icons` gem, so a custom library's
        location is configured there (rails_icons custom-library config), not
        in glyphs. Add validation for it in `.rubocop.yml` if you want lint-time
        checking:
      MD
      DocsUI::Code(<<~YAML, lexer: :yaml, filename: ".rubocop.yml")
        Glyphs/IconResolution:
          Libraries:
            BrandIcon: { Dir: brand, DefaultVariant: "" }
      YAML
    end
  end
end
