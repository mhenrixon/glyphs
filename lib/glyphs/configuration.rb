# frozen_string_literal: true

module Glyphs
  class Configuration
    DEFAULT_FALLBACK_ICONS = {
      lucide: "circle-question-mark",
      phosphor: "question",
      heroicons: "question-mark-circle"
    }.freeze

    # raise_on_missing_icon: callable -> bool; when true, Icons::IconNotFound is re-raised.
    # on_missing_icon: callable(error, name:, library:, variant:) instrumentation hook.
    # fallback_icons: { library => icon_name } rendered instead of a missing icon.
    # cache_svgs: memoize rendered SVG strings per [library, variant, name, attributes].
    attr_accessor :raise_on_missing_icon, :on_missing_icon, :fallback_icons, :cache_svgs

    def initialize
      @raise_on_missing_icon = -> { defined?(Rails) ? Rails.env.local? : true }
      @on_missing_icon = ->(error, name:, library:, variant:) {}
      @fallback_icons = DEFAULT_FALLBACK_ICONS.dup
      @cache_svgs = true
    end
  end
end
