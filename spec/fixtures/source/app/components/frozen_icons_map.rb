# frozen_string_literal: true

# Cross-file declaration harvest: icon names live only here, rendered
# dynamically from `selectable_row.rb` via `PhosphorIcon(@icon)`.
# The trailing `.freeze` used to hide HashNode values from declaration
# harvest (Prism sees a CallNode). Not loaded at runtime — only parsed
# by SourceScanner specs.
class FrozenIconsMap
  ICONS = {
    "driving_license" => :car,
    "residence_permit" => :identification_badge,
  }.freeze

  # Array form with freeze should harvest too.
  STATUS_ICONS = %i[warning check_circle].freeze
end
