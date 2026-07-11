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

    # Dynamic first arg — the scanner can't read the name off the call, but the
    # name IS a literal in this file's scope, so file-scoped harvesting keeps it
    # for the dynamically-rendered library (lucide here).
    status = :zap
    LucideIcon(status)

    # Dynamic variant / dynamic library still record nothing extra.
    HeroIcon(:check, variant: some_variant)
    Icon(:house, library: some_library)

    # A dynamic phosphor render whose names live in a local hash literal —
    # `icon:` hash values are icon-declaration positions, kept for phosphor.
    tiles = [{ label: "A", icon: :feather }, { label: "B", icon: "gear" }]
    tiles.each { |tile| PhosphorIcon(tile[:icon]) }
  end

  def some_variant = :outline
  def some_library = :lucide
end
