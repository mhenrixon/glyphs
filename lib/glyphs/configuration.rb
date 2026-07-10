# frozen_string_literal: true

module Glyphs
  class Configuration
    DEFAULT_FALLBACK_ICONS = {
      lucide: "circle-question-mark",
      phosphor: "question",
      heroicons: "question-mark-circle"
    }.freeze

    # raise_on_missing: boolean; when true, Icons::IconNotFound is re-raised.
    #   Defaults to true in local Rails environments (and outside Rails).
    # on_missing_icon: optional callable(error, name:, library:, variant:),
    #   invoked before the fallback renders when not raising.
    # fallback_icons: { library => icon_name } rendered instead of a missing icon.
    # cache_svgs: memoize rendered SVG strings per [library, variant, name, attributes].
    # keep_icons: icons the pruner must keep despite no static reference
    #   (dynamic / data-driven names). A flat list of names/globs, or a
    #   { library => [names/globs] } hash. fallback_icons are always kept.
    # prune_source_globs: extra source globs the pruner's scanner reads beyond
    #   the built-in Ruby/template defaults (nil = defaults only).
    attr_accessor :raise_on_missing, :on_missing_icon, :fallback_icons, :cache_svgs,
      :keep_icons, :prune_source_globs

    def initialize
      @raise_on_missing = defined?(Rails) ? Rails.env.local? : true
      @on_missing_icon = nil
      @fallback_icons = DEFAULT_FALLBACK_ICONS.dup
      @cache_svgs = true
      @keep_icons = []
      @prune_source_globs = nil
    end
  end
end
