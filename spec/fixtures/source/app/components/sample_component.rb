# frozen_string_literal: true

# A representative Phlex component exercising every icon call form the scanner
# must recognize. Not loaded at runtime — only parsed by SourceScanner specs.
class SampleComponent < Phlex::HTML
  include Glyphs

  def view_template
    LucideIcon(:house)
    LucideIcon("circle-check", class: "size-4")
    HeroIcon(:check, variant: :solid)
    PhosphorIcon("lock", variant: :bold)
    PhosphorIcon(:question)
    _lucide(:triangle_alert)
    _hero(:check)
    Icon(:house, library: :lucide)
    icon("check", library: "heroicons")
    span(class: "iconify lucide--menu size-4")

    # Dynamic — the scanner must skip these, not crash or record them.
    status = :zap
    LucideIcon(status)
    HeroIcon(:check, variant: some_variant)
    Icon(:house, library: some_library)
  end

  def some_variant = :outline
  def some_library = :lucide
end
