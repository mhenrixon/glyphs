# frozen_string_literal: true

# Icons the docs-kit chrome renders dynamically — their names live in the gem's
# data registry (topbar links, callouts, search box, theme switcher), not in
# this app's source, so a static scan can't see them. Declare them so the
# Docker-build icon prune (`glyphs:prune_icons`) keeps them.
#
# `circle-question-mark` is kept automatically: it's the lucide fallback icon
# (Glyphs::Configuration) and docs-kit's own MISSING_ICON.
Glyphs.configure do |config|
  config.keep_icons = %w[
    menu palette list file-code search info lightbulb triangle-alert clipboard
  ]
end
