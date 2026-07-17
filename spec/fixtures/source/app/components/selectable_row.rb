# frozen_string_literal: true

# Shared row that renders an icon passed in from another file. Forces a
# dynamic phosphor keep-set so FrozenIconsMap declarations are exercised
# as global declaration harvests. Not loaded at runtime — only parsed.
class SelectableRow < Phlex::HTML
  include Glyphs

  def initialize(icon:)
    @icon = icon
  end

  def view_template
    PhosphorIcon(@icon)
  end
end
