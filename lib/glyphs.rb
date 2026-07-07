# frozen_string_literal: true

require "phlex"
require "icons"
require "zeitwerk"
require_relative "glyphs/version"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/glyphs/version.rb")
# The RuboCop plugin lives in a foreign namespace and is only loaded inside a
# RuboCop process (see the bottom of this file).
loader.ignore("#{__dir__}/glyphs/rubocop.rb")
loader.ignore("#{__dir__}/rubocop")
loader.setup

# Ensure the icons gem is configured even outside Rails. Inside Rails the
# rails_icons engine calls `Icons.configure` with the app's settings; the
# configuration is memoized, so this never clobbers app configuration.
Icons.config

# Phlex icon components for every rails_icons library, exposed as a Phlex::Kit:
#
#   include Glyphs
#   LucideIcon(:house, class: "size-4")
module Glyphs
  extend Phlex::Kit

  @svg_cache = {}
  @svg_cache_mutex = Mutex.new

  class << self
    def configure
      yield(configuration) if block_given?
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    # Defines a `Glyphs::Icon` subclass for a custom icon library and exposes it
    # as a kit method. The library's SVG location itself is configured through
    # the icons/rails_icons custom-library configuration.
    #
    #   Glyphs.register_library(:brand, component: :BrandIcon)
    #   # => BrandIcon(:logo, class: "size-4")
    def register_library(library, component:)
      library = library.to_sym
      name = component.to_sym

      if const_defined?(name, false)
        existing = const_get(name, false)
        return existing if existing < Icon && library == existing::LIBRARY

        raise ArgumentError, "Glyphs::#{name} is already defined and does not render the #{library} library"
      end

      klass = Class.new(Icon)
      klass.const_set(:LIBRARY, library)
      const_set(name, klass)
    end

    # Returns the SVG markup for an icon, applying the configured missing-icon
    # policy (raise / instrument / fallback) and an optional per-process cache.
    def svg_for(name:, library:, variant:, attributes:)
      return render_svg(name:, library:, variant:, attributes:) unless configuration.cache_svgs

      key = [library, variant, name, attributes]
      @svg_cache_mutex.synchronize do
        @svg_cache[key] ||= render_svg(name:, library:, variant:, attributes:)
      end
    end

    def reset_cache!
      @svg_cache_mutex.synchronize { @svg_cache = {} }
    end

    private

    def render_svg(name:, library:, variant:, attributes:)
      build_svg(name:, library:, variant:, attributes:)
    rescue Icons::IconNotFound => e
      handle_missing_icon(e, name:, library:, variant:, attributes:)
    end

    def build_svg(name:, library:, variant:, attributes:)
      Icons::Icon.new(name:, library:, variant:, arguments: attributes).svg
    end

    def handle_missing_icon(error, name:, library:, variant:, attributes:)
      raise error if configuration.raise_on_missing

      configuration.on_missing_icon&.call(error, name:, library:, variant:)

      fallback = configuration.fallback_icons[library.to_sym]
      raise error if fallback.nil?

      begin
        build_svg(name: fallback, library:, variant:, attributes:)
      rescue Icons::IconNotFound
        raise error
      end
    end
  end
end

# Make the RuboCop plugin resolvable lazily: RuboCop constantizes
# Glyphs::RuboCop::Plugin (from the gemspec's default_lint_roller_plugin
# metadata) when it loads plugins, which can happen long after this gem was
# required — e.g. app boots first, cop specs load RuboCop later.
Glyphs.autoload :RuboCop, File.expand_path("glyphs/rubocop", __dir__)
