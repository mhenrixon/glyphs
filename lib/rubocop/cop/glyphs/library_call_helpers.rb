# frozen_string_literal: true

module RuboCop
  module Cop
    module Glyphs
      # Shared logic for cops that rewrite icon calls: locating a literal
      # `library:`/`from:` pair, mapping libraries to Glyphs components, and
      # removing the pair without leaving dangling commas.
      module LibraryCallHelpers
        LIBRARY_KEYS = %i[library from].freeze

        LIBRARY_TO_COMPONENT = {
          "lucide" => "LucideIcon",
          "phosphor" => "PhosphorIcon",
          "heroicons" => "HeroIcon",
          "tabler" => "TablerIcon",
          "feather" => "FeatherIcon",
          "boxicons" => "BoxIcon",
          "flags" => "FlagIcon",
          "hugeicons" => "HugeIcon",
          "linear" => "LinearIcon",
          "radix" => "RadixIcon",
          "sidekickicons" => "SidekickIcon",
          "weather" => "WeatherIcon",
          "animated" => "AnimatedIcon"
        }.freeze

        private

        def library_pair(node)
          hash = node.arguments.last
          return nil unless hash&.hash_type?

          hash.pairs.find { |pair| pair.key.sym_type? && LIBRARY_KEYS.include?(pair.key.value) }
        end

        def literal_pair?(pair)
          pair.value.str_type? || pair.value.sym_type?
        end

        def library_components
          @library_components ||= LIBRARY_TO_COMPONENT.merge(cop_config["LibraryComponents"] || {})
        end

        def remove_library_pair(corrector, pair)
          hash = pair.parent
          range = hash.pairs.one? ? hash.source_range : pair.source_range
          corrector.remove(
            range_with_surrounding_comma(range_with_surrounding_space(range, side: :left), :left)
          )
        end
      end
    end
  end
end
