# frozen_string_literal: true

module RuboCop
  module Cop
    module Glyphs
      # Replaces legacy icon helper calls with Glyphs kit components.
      #
      # @example
      #   # bad
      #   _lucide(:house, class: "size-4")
      #   icon("check", library: "lucide")
      #   icon("check")
      #
      #   # good
      #   LucideIcon(:house, class: "size-4")
      #   LucideIcon("check")
      #   HeroIcon("check") # `DefaultLibraryComponent` when no library: is given
      class LegacyIconHelper < Base
        include RangeHelp
        include LibraryCallHelpers
        extend AutoCorrector

        MSG = "Use `%{component}(...)` instead of `%{helper}(...)`."
        MSG_DYNAMIC = "Use a Glyphs component (e.g. `LucideIcon(...)`) instead of `icon(...)` with a dynamic library."
        MSG_UNKNOWN = "Use a Glyphs component instead of `icon(...)`; add a `LibraryComponents` mapping " \
                      "for library `%{library}`."

        DEFAULT_MAPPINGS = {
          _lucide: "LucideIcon",
          _phosphor: "PhosphorIcon",
          _hero: "HeroIcon",
          _heroicon: "HeroIcon",
          _tabler: "TablerIcon"
        }.freeze

        def on_send(node)
          return unless node.receiver.nil?

          if (component = mappings[node.method_name])
            rename_offense(node, component)
          elsif node.method_name == :icon && node.arguments.any?
            correct_icon_call(node)
          end
        end

        private

        def rename_offense(node, component)
          message = format(MSG, component:, helper: node.method_name)
          add_offense(node.loc.selector, message:) do |corrector|
            corrector.replace(node.loc.selector, component)
          end
        end

        def correct_icon_call(node)
          return if node.first_argument.hash_type? # no name argument; not an icon render call

          pair = library_pair(node)
          if pair.nil?
            rename_offense(node, default_component)
          elsif literal_pair?(pair)
            correct_icon_with_library(node, pair)
          else
            add_offense(node.loc.selector, message: MSG_DYNAMIC)
          end
        end

        def correct_icon_with_library(node, pair)
          library = pair.value.value.to_s
          component = library_components[library]

          if component.nil?
            add_offense(node.loc.selector, message: format(MSG_UNKNOWN, library:))
            return
          end

          message = format(MSG, component:, helper: :icon)
          add_offense(node.loc.selector, message:) do |corrector|
            corrector.replace(node.loc.selector, component)
            remove_library_pair(corrector, pair)
          end
        end

        def mappings
          @mappings ||= begin
            configured = cop_config["Mappings"] || {}
            configured.empty? ? DEFAULT_MAPPINGS : configured.to_h { |key, value| [key.to_sym, value.to_s] }
          end
        end

        def default_component
          cop_config["DefaultLibraryComponent"] || "HeroIcon"
        end
      end
    end
  end
end
