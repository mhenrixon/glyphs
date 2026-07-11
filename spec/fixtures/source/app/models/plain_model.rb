# frozen_string_literal: true

# No icon calls, no icon-declaration positions — just a bare string literal that
# happens to look like an icon name. Harvesting must NOT turn it into a kept
# reference (guards against the whole-codebase over-keep). Only parsed by specs.
class PlainModel
  STATUS = "definitely-not-an-icon"
end
