# frozen_string_literal: true

module RuboCop
  module Cop
    module Glyphs
      # Prefers library-specific components over the generic `Icon(...)` kit
      # call with a `library:` argument.
      #
      # @example
      #   # bad
      #   Icon(:house, library: :lucide)
      #
      #   # good
      #   LucideIcon(:house)
      class PreferLibraryComponent < Base
        include RangeHelp
        include LibraryCallHelpers
        extend AutoCorrector

        MSG = "Use `%{component}(...)` instead of `Icon(..., library: ...)`."
        MSG_DYNAMIC = "Prefer a library-specific Glyphs component over `Icon(...)` with a dynamic library."

        def on_send(node)
          return unless node.receiver.nil? && node.method_name == :Icon && node.arguments.any?

          pair = library_pair(node)
          return unless pair

          unless literal_pair?(pair)
            add_offense(node.loc.selector, message: MSG_DYNAMIC)
            return
          end

          component = library_components[pair.value.value.to_s]
          return unless component

          message = format(MSG, component:)
          add_offense(node.loc.selector, message:) do |corrector|
            corrector.replace(node.loc.selector, component)
            remove_library_pair(corrector, pair)
          end
        end
      end
    end
  end
end
