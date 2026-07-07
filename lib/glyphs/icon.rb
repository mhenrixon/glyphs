# frozen_string_literal: true

module Glyphs
  # Base icon component. Prefer the library-specific subclasses (LucideIcon,
  # HeroIcon, ...); the generic form requires an explicit library:
  #
  #   Icon(:house, library: :lucide)
  class Icon < Phlex::HTML
    LIBRARY = nil

    def initialize(name, variant: nil, library: self.class::LIBRARY, **attributes)
      if library.nil?
        raise ArgumentError,
          "library is required — use a library component (LucideIcon, HeroIcon, ...) or pass library:"
      end

      @name = name.to_s.tr("_", "-")
      @library = library.to_sym
      @variant = variant&.to_sym
      @attributes = attributes

      super()
    end

    def view_template
      raw safe(svg_markup)
    end

    private

    def svg_markup
      Glyphs.svg_for(name: @name, library: @library, variant: @variant, attributes: @attributes)
    end
  end
end
